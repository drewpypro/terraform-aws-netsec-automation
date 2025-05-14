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
  
  # Prepare individual rules for each CIDR in each consumer policy
  consumer_rules = flatten([
    for file, policy in local.consumer_policies : [
      for rule_idx, rule in policy.rules : [
        for cidr_idx, cidr in rule.source.ips : {
          key = "${file}-${rule_idx}-${cidr_idx}"
          policy = policy
          rule = rule
          cidr = cidr
          region = policy.security_group.region
          sg_name = "pl-consumer-${policy.security_group.thirdpartyName}-${policy.security_group.thirdPartyID}-${policy.security_group.region}"
          sg_description = "Security group for ${policy.security_group.thirdpartyName} PrivateLink (${policy.security_group.serviceName})"
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
  
  # Prepare individual rules for each CIDR in each provider policy
  provider_rules = flatten([
    for file, policy in local.provider_policies : [
      for rule_idx, rule in policy.rules : [
        for cidr_idx, cidr in rule.destination.ips : {
          key = "${file}-${rule_idx}-${cidr_idx}"
          policy = policy
          rule = rule
          cidr = cidr
          region = policy.security_group.region
          sg_name = "pl-provider-${policy.security_group.internalAppID}-${policy.security_group.region}"
          sg_description = "Security group for ${policy.security_group.internalAppID} PrivateLink provider"
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
  
  # Group rules by region for easier reference
  consumer_rules_by_region = {
    for region in local.regions : region => [
      for rule in local.consumer_rules :
      rule
      if rule.region == region
    ]
  }
  
  provider_rules_by_region = {
    for region in local.regions : region => [
      for rule in local.provider_rules :
      rule
      if rule.region == region
    ]
  }
  
  # NEW: Group consumer rules by security group name and region
  consumer_sg_rules = {
    for region in local.regions : region => {
      for sg_name in distinct([
        for rule in local.consumer_rules:
        rule.sg_name
        if rule.region == region
      ]) : sg_name => [
        for rule in local.consumer_rules:
        rule
        if rule.sg_name == sg_name && rule.region == region
      ]
    }
  }
  
  # NEW: Group provider rules by security group name and region
  provider_sg_rules = {
    for region in local.regions : region => {
      for sg_name in distinct([
        for rule in local.provider_rules:
        rule.sg_name
        if rule.region == region
      ]) : sg_name => [
        for rule in local.provider_rules:
        rule
        if rule.sg_name == sg_name && rule.region == region
      ]
    }
  }
}