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
  
  # Create security group definitions (one per thirdparty + region + service)
  consumer_security_groups = {
    for file, policy in local.consumer_policies :
    "${policy.security_group.thirdpartyName}-${policy.security_group.serviceName}-${policy.security_group.region}" => {
      policy = policy
      region = policy.security_group.region
      sg_name = "${policy.security_group.thirdpartyName}-${policy.security_group.serviceName}-${policy.security_group.region}-sg"
      sg_description = "Security group for ${policy.security_group.thirdpartyName} PrivateLink (${policy.security_group.serviceName})"
      tags = {
        ThirdPartyID = policy.security_group.thirdPartyID
        ThirdPartyName = policy.security_group.thirdpartyName
        ServiceType = "privatelink-consumer"
        RequestID = policy.security_group.request_id
        ServiceName = policy.security_group.serviceName
      }
    }
  }
  
  # Group rules by security group and protocol/port combination
  consumer_sg_rules = {
    for sg_key, sg_def in local.consumer_security_groups :
    sg_key => {
      sg_definition = sg_def
      # Group rules by protocol/port combination
      rules = {
        for rule_key, grouped_rule in {
          for rule in sg_def.policy.rules :
          "${rule.protocol}-${rule.port}" => {
            protocol = rule.protocol
            port = rule.port
            appid = rule.appid
            url = rule.url
            enable_palo_inspection = rule.enable_palo_inspection
            request_ids = distinct([rule.request_id])
            source_cidrs = rule.source.ips
            source_account_id = rule.source.account_id
            source_vpc_id = rule.source.vpc_id
            source_region = rule.source.region
          }...
        } :
        rule_key => {
          protocol = grouped_rule.protocol
          port = grouped_rule.port
          appid = grouped_rule.appid
          url = grouped_rule.url
          enable_palo_inspection = grouped_rule.enable_palo_inspection
          request_ids = grouped_rule.request_ids
          source_cidrs = distinct(flatten(grouped_rule.source_cidrs))
          source_account_id = grouped_rule.source_account_id
          source_vpc_id = grouped_rule.source_vpc_id
          source_region = grouped_rule.source_region
          rule_tags = {
            RequestIDs = join(",", grouped_rule.request_ids)
            SourceAccountID = grouped_rule.source_account_id
            SourceVPC = grouped_rule.source_vpc_id
            SourceRegion = grouped_rule.source_region
            EnablePaloInspection = tostring(grouped_rule.enable_palo_inspection)
            AppID = grouped_rule.appid
            URL = grouped_rule.url
          }
        }
      }
    }
  }
  
  # Group consumer rules by region
  consumer_rules_by_region = {
    for region in local.regions : region => {
      for sg_key, sg_rules in local.consumer_sg_rules :
      sg_key => sg_rules
      if sg_rules.sg_definition.region == region
    }
  }
  
  # Create Palo Alto rules aggregated by security group
  consumer_palo_rules = {
    for sg_key, sg_rules in local.consumer_sg_rules :
    sg_key => {
      sg_definition = sg_rules.sg_definition
      # Aggregate all sources and destinations for Palo Alto
      all_source_cidrs = distinct(flatten([
        for rule_key, rule in sg_rules.rules :
        rule.source_cidrs
      ]))
      all_appids = distinct([
        for rule_key, rule in sg_rules.rules :
        rule.appid
      ])
      all_urls = distinct([
        for rule_key, rule in sg_rules.rules :
        rule.url
      ])
      all_request_ids = distinct(flatten([
        for rule_key, rule in sg_rules.rules :
        rule.request_ids
      ]))
      enable_palo_inspection = anytrue([
        for rule_key, rule in sg_rules.rules :
        rule.enable_palo_inspection
      ])
      palo_rule_name = "pl-consumer-${sg_rules.sg_definition.policy.security_group.thirdpartyName}-${sg_rules.sg_definition.policy.security_group.serviceName}-allow"
      description = "PrivateLink access for ${sg_rules.sg_definition.policy.security_group.thirdpartyName} (${join(",", sg_rules.sg_definition.policy.security_group.serviceName)})"
    }
    if anytrue([
      for rule_key, rule in sg_rules.rules :
      rule.enable_palo_inspection
    ])
  }
  
  # Group Palo Alto rules by region
  consumer_palo_rules_by_region = {
    for region in local.regions : region => {
      for sg_key, palo_rule in local.consumer_palo_rules :
      sg_key => palo_rule
      if palo_rule.sg_definition.region == region
    }
  }
  
  # Provider security groups (keeping existing logic for now)
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
  
  provider_rules_by_region = {
    for region in local.regions : region => [
      for rule in local.provider_rules :
      rule
      if rule.region == region
    ]
  }
  
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