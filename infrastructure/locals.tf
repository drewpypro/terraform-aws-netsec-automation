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
  
  # Helper function to parse port ranges
  parse_port = {
    for file, policy in local.consumer_policies : file => {
      for rule_idx, rule in policy.rules : rule_idx => {
        from_port = contains(split("-", tostring(rule.port)), "-") ? tonumber(split("-", tostring(rule.port))[0]) : tonumber(rule.port)
        to_port = contains(split("-", tostring(rule.port)), "-") ? tonumber(split("-", tostring(rule.port))[1]) : tonumber(rule.port)
        port_key = tostring(rule.port)
      }
    }
  }
  
  # Flatten consumer rules for AWS SG (by protocol/port/cidr - each combination gets its own entry)
  consumer_aws_rule_combinations = flatten([
    for file, policy in local.consumer_policies : [
      for rule_idx, rule in policy.rules : [
        for cidr in rule.source.ips : {
          key = "${policy.security_group.thirdpartyName}-${policy.security_group.region}-${rule.protocol}-${rule.port}-${cidr}"
          sg_key = "${policy.security_group.thirdpartyName}-${policy.security_group.region}"
          region = policy.security_group.region
          sg_name = "${lower(policy.security_group.thirdpartyName)}-${replace(policy.security_group.serviceName, "com.amazonaws.vpce.", "")}-${policy.security_group.region}-sg"
          sg_description = "Security group for ${policy.security_group.thirdpartyName} PrivateLink (${policy.security_group.serviceName})"
          vpc_id = policy.security_group.vpc_id
          protocol = rule.protocol
          from_port = local.parse_port[file][rule_idx].from_port
          to_port = local.parse_port[file][rule_idx].to_port
          port_key = local.parse_port[file][rule_idx].port_key
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
            AppID = rule.appid != null && rule.appid != "" ? rule.appid : "any"
            URL = rule.url != null && rule.url != "" ? rule.url : "any"
          }
        }
      ]
    ]
  ])
  
  # Flatten consumer rules for Palo Alto (by protocol/port/appid/url - each combination gets grouped)
  consumer_palo_rule_combinations = flatten([
    for file, policy in local.consumer_policies : [
      for rule_idx, rule in policy.rules : {
        palo_key = "${policy.security_group.thirdpartyName}-${policy.security_group.region}-${rule.protocol}-${rule.port}-${rule.appid != null && rule.appid != "" ? rule.appid : "any"}-${rule.url != null && rule.url != "" ? replace(rule.url, "https://", "") : "any"}"
        sg_key = "${policy.security_group.thirdpartyName}-${policy.security_group.region}"
        region = policy.security_group.region
        protocol = rule.protocol
        from_port = local.parse_port[file][rule_idx].from_port
        to_port = local.parse_port[file][rule_idx].to_port
        port_key = local.parse_port[file][rule_idx].port_key
        appid = rule.appid != null && rule.appid != "" ? rule.appid : "any"
        url = rule.url != null && rule.url != "" ? replace(rule.url, "https://", "") : "any"
        source_ips = rule.source.ips
        enable_palo_inspection = rule.enable_palo_inspection
        request_id = rule.request_id
        policy = policy
      }
    ]
  ])
  
  # First, group combinations by region and sg_key for efficient access
  consumer_palo_combos_by_sg = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for combo in local.consumer_palo_rule_combinations :
        combo.sg_key
        if combo.region == region
      ]) : sg_key => [
        for combo in local.consumer_palo_rule_combinations :
        combo
        if combo.sg_key == sg_key && combo.region == region
      ]
    }
  }

  # Group Palo Alto rules by unique combination (protocol + port + appid + url)
  consumer_palo_grouped_rules = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for combo in local.consumer_palo_rule_combinations :
        combo.sg_key
        if combo.region == region
      ]) : sg_key => {
        # Group by palo_key and combine source IPs
        palo_rules = {
          for palo_key in distinct([
            for combo in local.consumer_palo_combos_by_sg[region][sg_key] :
            combo.palo_key
          ]) : palo_key => merge(
            # Get first combo for this palo_key to extract common properties
            [
              for combo in local.consumer_palo_combos_by_sg[region][sg_key] :
              {
                protocol = combo.protocol
                from_port = combo.from_port
                to_port = combo.to_port
                port_key = combo.port_key
                appid = combo.appid
                url = combo.url
                enable_palo_inspection = combo.enable_palo_inspection
              }
              if combo.palo_key == palo_key
            ][0],
            {
              # Combine all source IPs for this unique combination
              source_ips = distinct(flatten([
                for combo in local.consumer_palo_combos_by_sg[region][sg_key] :
                combo.source_ips
                if combo.palo_key == palo_key
              ]))
            }
          )
        }
        
        # Get policy info from first combo
        policy_info = local.consumer_palo_combos_by_sg[region][sg_key][0].policy
      }
    }
  }
  
  # First, create a map of consumer security groups with their first combo for reference
  consumer_sg_first_combo = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for combo in local.consumer_aws_rule_combinations :
        combo.sg_key
        if combo.region == region
      ]) : sg_key => [
        for combo in local.consumer_aws_rule_combinations :
        combo
        if combo.sg_key == sg_key && combo.region == region
      ][0]
    }
  }
  
  # Group consumer combinations by security group for AWS
  consumer_sgs_by_region = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for combo in local.consumer_aws_rule_combinations :
        combo.sg_key
        if combo.region == region
      ]) : sg_key => {
        region = region
        sg_name = local.consumer_sg_first_combo[region][sg_key].sg_name
        sg_description = local.consumer_sg_first_combo[region][sg_key].sg_description
        vpc_id = local.consumer_sg_first_combo[region][sg_key].vpc_id
        tags = local.consumer_sg_first_combo[region][sg_key].tags
        
        # Create individual AWS security group rules (one per protocol/port/cidr)
        aws_rules = {
          for combo in local.consumer_aws_rule_combinations :
          combo.key => {
            protocol = combo.protocol
            from_port = combo.from_port
            to_port = combo.to_port
            cidr = combo.cidr
            description = "Allow access from ${combo.rule.source.account_id} (${combo.rule.request_id})"
            rule_tags = combo.rule_tags
          }
          if combo.sg_key == sg_key && combo.region == region
        }
        
        # Palo Alto grouped rules
        palo_rules = try(local.consumer_palo_grouped_rules[region][sg_key].palo_rules, {})
        
        # Get policy info for Palo Alto configuration
        policy_info = try(local.consumer_palo_grouped_rules[region][sg_key].policy_info, local.consumer_sg_first_combo[region][sg_key].policy)
        
        # Palo Alto common settings
        service_name = policy_info.security_group.serviceName
        name_prefix = policy_info.security_group.thirdpartyName
        request_id = policy_info.security_group.request_id
      }
    }
  }
}