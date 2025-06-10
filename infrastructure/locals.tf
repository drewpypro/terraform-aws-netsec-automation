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
          dedup_key = "${policy.security_group.thirdpartyName}-${policy.security_group.region}-${rule.protocol}-${rule.port}-${cidr}"
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
  
  # Deduplicated AWS SG rules: group by sg_key + cidr + proto + port
  deduped_consumer_aws_rules = {
    for combo in distinct([
      for c in local.consumer_rule_combinations : {
        sg_key   = c.sg_key
        region   = c.region
        protocol = c.protocol
        port     = c.port
        cidr     = c.cidr
      }
    ]) : 
    "${combo.sg_key}-${combo.protocol}-${combo.port}-${combo.cidr}" => combo
  }


  # Flatten provider rules by protocol/port/cidr - each combination gets its own entry
  provider_rule_combinations = flatten([
    for file, policy in local.provider_policies : [
      for rule_idx, rule in policy.rules : [
        for cidr in rule.destination.ips : {
          key = "${policy.security_group.internalAppID}-${policy.security_group.region}-${rule.protocol}-${rule.port}-${cidr}"
          sg_key = "${policy.security_group.internalAppID}-${policy.security_group.region}"
          region = policy.security_group.region
          sg_name = "pl-provider-${policy.security_group.internalAppID}-${policy.security_group.region}"
          sg_description = "Security group for ${policy.security_group.internalAppID} PrivateLink provider"
          vpc_id = policy.security_group.vpc_id
          protocol = rule.protocol
          port = rule.port
          cidr = cidr
          rule = rule
          policy = policy
          tags = {
            InternalAppID = policy.security_group.internalAppID
            ServiceType = "privatelink-provider"
            RequestID = policy.security_group.request_id
          }
          rule_tags = {
            RequestID = rule.request_id
            EnablePaloInspection = tostring(rule.enable_palo_inspection)
            AppID = rule.appid
            URL = rule.url
          }
        }
      ]
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

  # Deduplicate AWS rules  
  consumer_aws_rules_deduped = {
    for combo in local.consumer_rule_combinations :
    combo.dedup_key => combo
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
        sg_name = local.consumer_sg_first_combo[region][sg_key].sg_name
        sg_description = local.consumer_sg_first_combo[region][sg_key].sg_description
        vpc_id = local.consumer_sg_first_combo[region][sg_key].vpc_id
        tags = local.consumer_sg_first_combo[region][sg_key].tags
        
        # AWS rules (deduplicated)
        aws_rules = {
          for key, combo in local.deduped_consumer_aws_rules :
          combo.key => {
            protocol = combo.protocol
            port = combo.port
            cidr = combo.cidr
            description = "Allow access from ${combo.rule.source.account_id} (${combo.rule.request_id})"
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
        palo_source_ips = distinct([
          for combo in values(local.consumer_aws_rules_deduped) :
          combo.cidr
          if combo.sg_key == sg_key && combo.region == region
        ])
      }
    }
  }
}

output "raw_combos" {
  value = [for c in local.consumer_rule_combinations : {
    sg_key = c.sg_key
    proto = c.protocol
    port = c.port
    cidr = c.cidr
    appid = c.rule.appid
    url = c.rule.url
  }]
}