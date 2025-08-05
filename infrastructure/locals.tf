locals {
  # Load and parse all policy files
  policy_files = fileset("${path.module}/policies", "*-policy.yaml")
  policies = {
    for file in local.policy_files :
    file => yamldecode(file("${path.module}/policies/${file}"))
  }
  
  regions = distinct([
    for file, policy in local.policies :
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
    for file, policy in local.consumer_policies : [
      for rule_idx, rule in policy.rules : [
        for cidr_idx, cidr in rule.source.ips : {
          key = "${policy.security_group.thirdpartyName}-${replace(policy.security_group.serviceName, "com.amazonaws.vpce.", "")}-${policy.security_group.region}-${rule.protocol}-${rule.port}-${cidr}-${rule_idx}-${cidr_idx}"
          dedup_key = "${policy.security_group.thirdpartyName}-${replace(policy.security_group.serviceName, "com.amazonaws.vpce.", "")}-${policy.security_group.region}-${rule.protocol}-${rule.port}-${cidr}"
          sg_key = "${policy.security_group.thirdpartyName}-${replace(policy.security_group.serviceName, "com.amazonaws.vpce.", "")}-${policy.security_group.region}"
          region = policy.security_group.region
          sg_name = "${lower(policy.security_group.thirdpartyName)}-${replace(policy.security_group.serviceName, "com.amazonaws.vpce.", "")}-${policy.security_group.region}-sg"
          sg_description = "Security group for ${policy.security_group.thirdpartyName} PrivateLink (${policy.security_group.serviceName})"
          vpc_id = policy.security_group.vpc_id
          protocol = rule.protocol
          port = rule.port
          cidr = cidr
          rule = rule
          policy = policy
        }
      ]
    ]
  ])
 
  consumer_palo_rule_combinations = flatten([
    for file, policy in local.consumer_policies : [
      for rule_idx, rule in policy.rules : [
        for cidr in rule.source.ips : {
          palo_key = "${policy.security_group.thirdpartyName}-${replace(policy.security_group.serviceName, "com.amazonaws.vpce.", "")}-${policy.security_group.region}-${rule.protocol}-${rule.port}-${rule.appid != null && rule.appid != "" ? rule.appid : "any"}-${rule.url != null && rule.url != "" ? replace(rule.url, "https://", "") : "any"}"
          sg_key = "${policy.security_group.thirdpartyName}-${replace(policy.security_group.serviceName, "com.amazonaws.vpce.", "")}-${policy.security_group.region}"
          region = policy.security_group.region
          protocol = rule.protocol
          port = rule.port
          appid = rule.appid != null && rule.appid != "" ? rule.appid : "any"
          url = rule.url != null && rule.url != "" ? rule.url : "any"
          source_ips = [cidr]
          enable_palo_inspection = rule.enable_palo_inspection
          policy = policy
        }
      ]
    ]
  ])

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
            source_ips = [
              for combo in local.consumer_palo_rule_combinations :
              combo.source_ips[0]
              if combo.palo_key == palo_key && combo.sg_key == sg_key && combo.region == region
            ]
            enable_palo_inspection = [for combo in local.consumer_palo_rule_combinations : combo.enable_palo_inspection if combo.palo_key == palo_key && combo.sg_key == sg_key && combo.region == region][0]
          }
        }
      }
    }
  }

  # ----
  # DEDUPLICATED OBJECTS FOR THE palo-objects MODULE
  # ----

  # Unique service objects for Palo (e.g. tcp-443-445, tcp-69, etc.)
  palo_service_objects = distinct(flatten([
    for region, sg_group in local.consumer_palo_grouped_rules : [
      for sg_key, sg_obj in sg_group : [
        for _, rule in sg_obj.palo_rules : [
          "${rule.protocol}-${rule.port}"
        ]
      ]
    ]
  ]))

  # Unique tags for Palo objects (customize as needed)
  palo_tags = distinct(flatten([
    for region, sg_group in local.consumer_palo_grouped_rules : [
      for sg_key, sg_obj in sg_group : [
        sg_key,
        "privatelink-consumer",
        # Could add more keys here if needed, e.g. thirdpartyName, region, etc.
        region
      ]
    ]
  ]))

  # Unique url categories for Palo
  palo_url_categories = distinct(flatten([
    for region, sg_group in local.consumer_palo_grouped_rules : [
      for sg_key, sg_obj in sg_group : [
        for _, rule in sg_obj.palo_rules : [
          rule.url != null && rule.url != "" && rule.url != "any" ? replace(replace(rule.url, "https://", ""), "/", "-") : null
        ]
      ]
    ]
  ]))
  palo_url_categories_filtered = [for url in local.palo_url_categories : url if url != null && url != ""]

  # ----
  # THE REST OF YOUR EXISTING LOCALS
  # ----

  consumer_aws_rules_grouped = {
    for combo in local.consumer_rule_combinations :
    combo.dedup_key => combo...
  }
  consumer_aws_rules_deduped = {
    for key, combos in local.consumer_aws_rules_grouped :
    key => combos[0]
  }

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

        aws_rules = {
          for combo in values(local.consumer_aws_rules_deduped) :
          combo.dedup_key => {
            protocol = combo.protocol
            port = combo.port
            from_port   = contains(combo.port, "-") ? tonumber(split("-", combo.port)[0]) : tonumber(combo.port)
            to_port     = contains(combo.port, "-") ? tonumber(split("-", combo.port)[1]) : tonumber(combo.port)
            cidr = combo.cidr
            description = "Allow access from ${combo.rule.source.account_id} (${combo.rule.request_id})"
            # rule_tags can be added if needed
          }
          if combo.sg_key == sg_key && combo.region == region
        }

        palo_rules = try(local.consumer_palo_grouped_rules[region][sg_key].palo_rules, {})

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
