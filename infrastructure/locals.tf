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
        for cidr in rule.source.ips : {
          key = "${policy.security_group.thirdpartyName}-${policy.security_group.region}-${rule.protocol}-${rule.port}-${cidr}"
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
  
  # Group consumer combinations by security group
  consumer_sgs_by_region = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for combo in local.consumer_rule_combinations :
        combo.sg_key
        if combo.region == region
      ]) : sg_key => {
        # Get the first combo for this SG to extract common properties
        first_combo = [
          for combo in local.consumer_rule_combinations :
          combo
          if combo.sg_key == sg_key && combo.region == region
        ][0]
        
        region = region
        sg_name = first_combo.sg_name
        sg_description = first_combo.sg_description
        vpc_id = first_combo.vpc_id
        tags = first_combo.tags
        
        # Create individual AWS security group rules (one per protocol/port/cidr)
        aws_rules = {
          for combo in local.consumer_rule_combinations :
          combo.key => {
            protocol = combo.protocol
            port = combo.port
            cidr = combo.cidr
            description = "Allow access from ${combo.rule.source.account_id} (${combo.rule.request_id})"
            rule_tags = combo.rule_tags
          }
          if combo.sg_key == sg_key && combo.region == region
        }
        
        # Collect Palo Alto data (all unique protocols/ports and all source IPs)
        palo_protocols_ports = distinct([
          for combo in local.consumer_rule_combinations :
          "${combo.protocol}-${combo.port}"
          if combo.sg_key == sg_key && combo.region == region
        ])
        
        palo_source_ips = distinct([
          for combo in local.consumer_rule_combinations :
          combo.cidr
          if combo.sg_key == sg_key && combo.region == region
        ])
        
        # Palo Alto common settings from first rule
        enable_palo_inspection = first_combo.rule.enable_palo_inspection
        name_prefix = first_combo.policy.security_group.thirdpartyName
        request_id = first_combo.policy.security_group.request_id
        appid = first_combo.rule.appid
        url = first_combo.rule.url
      }
    }
  }
  
  # Group provider combinations by security group
  provider_sgs_by_region = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for combo in local.provider_rule_combinations :
        combo.sg_key
        if combo.region == region
      ]) : sg_key => {
        # Get the first combo for this SG to extract common properties
        first_combo = [
          for combo in local.provider_rule_combinations :
          combo
          if combo.sg_key == sg_key && combo.region == region
        ][0]
        
        region = region
        sg_name = first_combo.sg_name
        sg_description = first_combo.sg_description
        vpc_id = first_combo.vpc_id
        tags = first_combo.tags
        
        # Create individual AWS security group rules (one per protocol/port/cidr)
        aws_rules = {
          for combo in local.provider_rule_combinations :
          combo.key => {
            protocol = combo.protocol
            port = combo.port
            cidr = combo.cidr
            description = "Allow access to backend (${combo.rule.request_id})"
            rule_tags = combo.rule_tags
          }
          if combo.sg_key == sg_key && combo.region == region
        }
        
        # Collect Palo Alto data (all unique protocols/ports and all destination IPs)
        palo_protocols_ports = distinct([
          for combo in local.provider_rule_combinations :
          "${combo.protocol}-${combo.port}"
          if combo.sg_key == sg_key && combo.region == region
        ])
        
        palo_destination_ips = distinct([
          for combo in local.provider_rule_combinations :
          combo.cidr
          if combo.sg_key == sg_key && combo.region == region
        ])
        
        # Palo Alto common settings from first rule
        enable_palo_inspection = first_combo.rule.enable_palo_inspection
        name_prefix = first_combo.policy.security_group.internalAppID
        request_id = first_combo.policy.security_group.request_id
        appid = first_combo.rule.appid
        url = first_combo.rule.url
      }
    }
  }
}