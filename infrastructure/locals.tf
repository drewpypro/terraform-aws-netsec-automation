locals {
  policy_files = fileset("${path.module}/policies", "*-policy.yaml")

  policies = {
    for file in local.policy_files :
    file => yamldecode(file("${path.module}/policies/${file}"))
  }

  regions = distinct([
    for _, policy in local.policies :
    policy.security_group.region
  ])

  consumer_policies = {
    for file, policy in local.policies :
    file => policy
    if policy.security_group.serviceType == "privatelink-consumer"
  }

  provider_policies = {
    for file, policy in local.policies :
    file => policy
    if policy.security_group.serviceType == "privatelink-provider"
  }

  consumer_rule_combinations = flatten([
    for _, policy in local.consumer_policies : [
      for rule in policy.rules : [
        for cidr in rule.source.ips : {
          key             = "${policy.security_group.thirdpartyName}-${policy.security_group.region}-${rule.protocol}-${rule.port}-${cidr}"
          sg_key          = "${policy.security_group.thirdpartyName}-${policy.security_group.region}"
          region          = policy.security_group.region
          sg_name         = "${lower(policy.security_group.thirdpartyName)}-${replace(policy.security_group.serviceName, "com.amazonaws.vpce.", "")}-${policy.security_group.region}-sg"
          sg_description  = "Security group for ${policy.security_group.thirdpartyName} PrivateLink (${policy.security_group.serviceName})"
          vpc_id          = policy.security_group.vpc_id
          protocol        = rule.protocol
          port            = rule.port
          cidr            = cidr
          rule            = rule
          policy          = policy
          tags = {
            ThirdPartyID   = policy.security_group.thirdPartyID
            ThirdPartyName = policy.security_group.thirdpartyName
            ServiceType    = "privatelink-consumer"
            RequestID      = policy.security_group.request_id
            ServiceName    = policy.security_group.serviceName
          }
          rule_tags = {
            RequestID        = rule.request_id
            SourceAccountID  = rule.source.account_id
            SourceVPC        = rule.source.vpc_id
            SourceRegion     = rule.source.region
            EnablePaloInspection = tostring(rule.enable_palo_inspection)
            AppID            = rule.appid
            URL              = rule.url
          }
        }
      ]
    ]
  ])

  deduped_consumer_aws_rules = {
    for k, v in tomap({
      for combo in local.consumer_rule_combinations :
      "${combo.sg_key}-${combo.protocol}-${combo.port}-${combo.cidr}" => combo
    }) : k => v
  }

  provider_rule_combinations = flatten([
    for _, policy in local.provider_policies : [
      for rule in policy.rules : [
        for cidr in rule.destination.ips : {
          key            = "${policy.security_group.internalAppID}-${policy.security_group.region}-${rule.protocol}-${rule.port}-${cidr}"
          sg_key         = "${policy.security_group.internalAppID}-${policy.security_group.region}"
          region         = policy.security_group.region
          sg_name        = "pl-provider-${policy.security_group.internalAppID}-${policy.security_group.region}"
          sg_description = "Security group for ${policy.security_group.internalAppID} PrivateLink provider"
          vpc_id         = policy.security_group.vpc_id
          protocol       = rule.protocol
          port           = rule.port
          cidr           = cidr
          rule           = rule
          policy         = policy
          tags = {
            InternalAppID = policy.security_group.internalAppID
            ServiceType   = "privatelink-provider"
            RequestID     = policy.security_group.request_id
          }
          rule_tags = {
            RequestID            = rule.request_id
            EnablePaloInspection = tostring(rule.enable_palo_inspection)
            AppID                = rule.appid
            URL                  = rule.url
          }
        }
      ]
    ]
  ])

  consumer_sg_first_combo = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for c in local.consumer_rule_combinations :
        c.sg_key if c.region == region
      ]) : sg_key => [
        for c in local.consumer_rule_combinations :
        c if c.sg_key == sg_key && c.region == region
      ][0]
    }
  }

  consumer_sgs_by_region = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for c in local.consumer_rule_combinations :
        c.sg_key if c.region == region
      ]) : sg_key => {
        first_combo           = local.consumer_sg_first_combo[region][sg_key]
        region                = region
        sg_name               = first_combo.sg_name
        sg_description        = first_combo.sg_description
        vpc_id                = first_combo.vpc_id
        tags                  = first_combo.tags

        aws_rules = {
          for k, combo in local.deduped_consumer_aws_rules :
          combo.key => {
            protocol    = combo.protocol
            port        = combo.port
            cidr        = combo.cidr
            description = "Allow access from ${combo.rule.source.account_id} (${combo.rule.request_id})"
            rule_tags   = combo.rule_tags
          }
          if combo.sg_key == sg_key && combo.region == region
        }

        palo_protocols_ports = distinct([
          for c in local.consumer_rule_combinations :
          "${c.protocol}-${c.port}" if c.sg_key == sg_key && c.region == region
        ])

        palo_service_objects = {
          for protocol_port in palo_protocols_ports : protocol_port => {
            name            = protocol_port
            protocol        = split("-", protocol_port)[0]
            destination_port = split("-", protocol_port)[1]
          }
        }

        palo_source_ips = distinct([
          for c in local.consumer_rule_combinations :
          c.cidr if c.sg_key == sg_key && c.region == region
        ])

        palo_url_category = {
          name = "${first_combo.policy.security_group.thirdpartyName}-${first_combo.policy.security_group.request_id}-urls"
          urls = [replace(first_combo.rule.url, "https://", "")]
        }

        palo_rules = [
          for c in local.consumer_rule_combinations :
          {
            cidr  = c.cidr
            proto = c.protocol
            port  = c.port
            appid = try(c.rule.appid, null)
            url   = try(c.rule.url, null)
          }
          if c.sg_key == sg_key && c.region == region
        ]

        enable_palo_inspection = first_combo.rule.enable_palo_inspection
        name_prefix            = first_combo.policy.security_group.thirdpartyName
        request_id             = first_combo.policy.security_group.request_id
        appid                  = first_combo.rule.appid
        url                    = first_combo.rule.url
      }
    }
  }

}
