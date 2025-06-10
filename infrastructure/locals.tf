locals {
  # Load and parse all policy files
  policy_files = fileset("${path.module}/policies", "*-policy.yaml")
  policies = {
    for file in local.policy_files :
    file => yamldecode(file("${path.module}/policies/${file}"))
  }
  
  # Get unique regions
  regions = distinct([
    for file, policy in local.policies :
    policy.security_group.region
  ])
  
  # Process consumer privatelink policies
  consumer_policies = {
    for file, policy in local.policies :
    file => policy
    if policy.security_group.serviceType == "privatelink-consumer"
  }
  
  # Process provider privatelink policies
  provider_policies = {
    for file, policy in local.policies :
    file => policy
    if policy.security_group.serviceType == "privatelink-provider"
  }
  
  # Flatten consumer rules by protocol/port/cidr - each combination gets its own entry
  consumer_rule_combinations = flatten([
    for file, policy in local.consumer_policies : [
      for rule_idx, rule in policy.rules : [
        for cidr_idx, cidr in rule.source.ips : {
          key = "${policy.security_group.thirdpartyName}-${policy.security_group.region}-${rule.protocol}-${rule.port}-${cidr}-${rule_idx}-${cidr_idx}"
          dedup_key = "${policy.security_group.thirdpartyName}-${policy.security_group.region}-${rule.protocol}-${rule.port}"  # ✅ REMOVED CIDR
          sg_key = "${policy.security_group.thirdpartyName}-${policy.security_group.region}"
          region = policy.security_group.region
          sg_name = "${lower(policy.security_group.thirdpartyName)}-${replace(policy.security_group.serviceName, "com.amazonaws.vpce.", "")}-${policy.security_group.region}-sg"
          sg_description = "Security group for ${policy.security_group.thirdpartyName} PrivateLink (${policy.security_group.serviceName})"
          vpc_id = policy.security_group.vpc_id
          protocol = rule.protocol
          port = rule.port
          cidr = cidr
          rule = rule
          policy = policy
          tags = {
            ThirdPartyID = policy.security_group.thirdPartyID
            ThirdPartyName = policy.security_group.thirdpartyName
            ServiceType = "privatelink-consumer"
            RequestID = policy.security_group.request_id
            ServiceName = policy.security_group.serviceName
          }
          rule_tags = {
            RequestID = rule.request_id
            SourceAccountID = rule.source.account_id
            SourceVPC = rule.source.vpc_id
            SourceRegion = rule.source.region
            EnablePaloInspection = tostring(rule.enable_palo_inspection)
            AppID = rule.appid
            URL = rule.url
          }
        }
      ]
    ]
  ])

  # NEW: Group Palo Alto rules by protocol+port+appid+url
  consumer_palo_rule_combinations = flatten([
    for file, policy in local.consumer_policies : [
      for rule_idx, rule in policy.rules : {
        palo_key = "${policy.security_group.thirdpartyName}-${policy.security_group.region}-${rule.protocol}-${rule.port}-${rule.appid != null && rule.appid != "" ? rule.appid : "any"}-${rule.url != null && rule.url != "" ? replace(rule.url, "https://", "") : "any"}"
        sg_key = "${policy.security_group.thirdpartyName}-${policy.security_group.region}"
        region = policy.security_group.region
        protocol = rule.protocol
        port = rule.port
        appid = rule.appid != null && rule.appid != "" ? rule.appid : "any"
        url = rule.url != null && rule.url != "" ? replace(rule.url, "https://", "") : "any"
        source_ips = rule.source.ips
        enable_palo_inspection = rule.enable_palo_inspection
        policy = policy
      }
    ]
  ])

  # NEW: Group Palo Alto rules by unique combination
  consumer_palo_grouped_rules = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for combo in local.consumer_palo_rule_combinations :
        combo.sg_key
        if combo.region == region
      ]) : sg_key => {
        palo_rules = {
          for palo_key in distinct([
            for combo in local.consumer_palo_rule_combinations :
            combo.palo_key
            if combo.sg_key == sg_key && combo.region == region
          ]) : palo_key => {
            protocol = [for combo in local.consumer_palo_rule_combinations : combo.protocol if combo.palo_key == palo_key && combo.sg_key == sg_key && combo.region == region][0]
            port = [for combo in local.consumer_palo_rule_combinations : combo.port if combo.palo_key == palo_key && combo.sg_key == sg_key && combo.region == region][0]
            appid = [for combo in local.consumer_palo_rule_combinations : combo.appid if combo.palo_key == palo_key && combo.sg_key == sg_key && combo.region == region][0]
            url = [for combo in local.consumer_palo_rule_combinations : combo.url if combo.palo_key == palo_key && combo.sg_key == sg_key && combo.region == region][0]
            source_ips = distinct(flatten([for combo in local.consumer_palo_rule_combinations : combo.source_ips if combo.palo_key == palo_key && combo.sg_key == sg_key && combo.region == region]))
            enable_palo_inspection = [for combo in local.consumer_palo_rule_combinations : combo.enable_palo_inspection if combo.palo_key == palo_key && combo.sg_key == sg_key && combo.region == region][0]
          }
        }
      }
    }
  }

  # ✅ Group AWS rules by protocol/port and collect all CIDRs
  consumer_aws_rules_deduped = {
    for combo in local.consumer_rule_combinations :
    combo.dedup_key => {
      protocol = combo.protocol
      port = combo.port
      # ✅ Collect all CIDRs for this protocol/port combination
      cidrs = distinct([
        for c in local.consumer_rule_combinations :
        c.cidr
        if c.dedup_key == combo.dedup_key
      ])
      description = "Allow access for ${combo.policy.security_group.thirdpartyName} ${combo.protocol}/${combo.port}"
      rule_tags = combo.rule_tags
      sg_key = combo.sg_key
      region = combo.region
      policy = combo.policy
      rule = combo.rule
    }
    ... # ✅ Use ellipsis to handle duplicate keys
  }
  
  # First, create a map of consumer security groups with their first combo for reference
  consumer_sg_first_combo = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for combo in values(local.consumer_aws_rules_deduped) :
        combo.sg_key
        if combo.region == region
      ]) : sg_key => [
        for combo in values(local.consumer_aws_rules_deduped) :
        combo
        if combo.sg_key == sg_key && combo.region == region
      ][0]
    }
  }
  
  # Group consumer combinations by security group
  consumer_sgs_by_region = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for combo in values(local.consumer_aws_rules_deduped) :
        combo.sg_key
        if combo.region == region
      ]) : sg_key => {
        region = region
        sg_name = local.consumer_sg_first_combo[region][sg_key].policy.security_group.thirdpartyName != null ? "${lower(local.consumer_sg_first_combo[region][sg_key].policy.security_group.thirdpartyName)}-${replace(local.consumer_sg_first_combo[region][sg_key].policy.security_group.serviceName, "com.amazonaws.vpce.", "")}-${region}-sg" : "default-sg"
        sg_description = local.consumer_sg_first_combo[region][sg_key].policy.security_group.thirdpartyName != null ? "Security group for ${local.consumer_sg_first_combo[region][sg_key].policy.security_group.thirdpartyName} PrivateLink (${local.consumer_sg_first_combo[region][sg_key].policy.security_group.serviceName})" : "Default security group"
        vpc_id = local.consumer_sg_first_combo[region][sg_key].policy.security_group.vpc_id
        tags = {
          ThirdPartyID = local.consumer_sg_first_combo[region][sg_key].policy.security_group.thirdPartyID
          ThirdPartyName = local.consumer_sg_first_combo[region][sg_key].policy.security_group.thirdpartyName
          ServiceType = "privatelink-consumer"
          RequestID = local.consumer_sg_first_combo[region][sg_key].policy.security_group.request_id
          ServiceName = local.consumer_sg_first_combo[region][sg_key].policy.security_group.serviceName
        }
        
        # ✅ AWS rules (grouped by protocol/port with merged CIDRs)
        aws_rules = {
          for combo in values(local.consumer_aws_rules_deduped) :
          combo.dedup_key => {
            protocol = combo.protocol
            port = combo.port
            cidrs = combo.cidrs  # ✅ Now this is a list of CIDRs
            description = combo.description
            rule_tags = combo.rule_tags
          }
          if combo.sg_key == sg_key && combo.region == region
        }
        
        # NEW: Palo Alto grouped rules
        palo_rules = try(local.consumer_palo_grouped_rules[region][sg_key].palo_rules, {})
        
        # Palo Alto common settings
        enable_palo_inspection = local.consumer_sg_first_combo[region][sg_key].rule.enable_palo_inspection
        name_prefix = local.consumer_sg_first_combo[region][sg_key].policy.security_group.thirdpartyName
        request_id = local.consumer_sg_first_combo[region][sg_key].policy.security_group.request_id
        appid = local.consumer_sg_first_combo[region][sg_key].rule.appid
        url = local.consumer_sg_first_combo[region][sg_key].rule.url
        palo_protocols_ports = distinct([
          for combo in values(local.consumer_aws_rules_deduped) :
          "${combo.protocol}-${combo.port}"
          if combo.sg_key == sg_key && combo.region == region
        ])
        palo_source_ips = distinct(flatten([
          for combo in values(local.consumer_aws_rules_deduped) :
          combo.cidrs  # ✅ Updated to use cidrs (list) instead of cidr
          if combo.sg_key == sg_key && combo.region == region
        ]))
      }
    }
  }
}