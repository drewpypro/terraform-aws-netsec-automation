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
  
  # Flatten all consumer rules into individual entries
  consumer_rule_entries = flatten([
    for file, policy in local.consumer_policies : [
      for rule_idx, rule in policy.rules : [
        for cidr in rule.source.ips : {
          sg_key = "${policy.security_group.thirdpartyName}-${policy.security_group.region}"
          region = policy.security_group.region
          policy = policy
          rule = rule
          cidr = cidr
          
          # For AWS SG grouping key
          aws_key = "${cidr}-${rule.protocol}-${rule.port}"
          
          # For Palo Alto grouping key  
          palo_key = "${rule.protocol}-${rule.port}-${coalesce(rule.appid, "any")}-${rule.url != null && rule.url != "" ? rule.url : "any"}"
        }
      ]
    ]
  ])
  
  # Group consumer security groups by region
  consumer_sgs_by_region = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for entry in local.consumer_rule_entries :
        entry.sg_key
        if entry.region == region
      ]) : sg_key => {
        # Get reference entry for SG metadata
        ref_entry = [
          for entry in local.consumer_rule_entries :
          entry
          if entry.sg_key == sg_key && entry.region == region
        ][0]
        
        region = region
        sg_name = "${lower(ref_entry.policy.security_group.thirdpartyName)}-${replace(ref_entry.policy.security_group.serviceName, "com.amazonaws.vpce.", "")}-${region}-sg"
        sg_description = "Security group for ${ref_entry.policy.security_group.thirdpartyName} PrivateLink (${ref_entry.policy.security_group.serviceName})"
        vpc_id = ref_entry.policy.security_group.vpc_id
        service_name = ref_entry.policy.security_group.serviceName
        tags = {
          ThirdPartyID = ref_entry.policy.security_group.thirdPartyID
          ThirdPartyName = ref_entry.policy.security_group.thirdpartyName
          ServiceType = "privatelink-consumer"
          RequestID = ref_entry.policy.security_group.request_id
          ServiceName = ref_entry.policy.security_group.serviceName
        }
        
        # AWS Rules: Group by cidr + protocol + port (unique combinations only)
        aws_rules = {
          for aws_key in distinct([
            for entry in local.consumer_rule_entries :
            entry.aws_key
            if entry.sg_key == sg_key && entry.region == region
          ]) : aws_key => {
            # Get representative entry for this AWS grouping
            aws_entry = [
              for entry in local.consumer_rule_entries :
              entry
              if entry.sg_key == sg_key && entry.region == region && entry.aws_key == aws_key
            ][0]
            
            protocol = aws_entry.rule.protocol
            port = aws_entry.rule.port
            cidr = aws_entry.cidr
            # Parse port range if needed
            port_parts = split("-", aws_entry.rule.port)
            from_port = tonumber(port_parts[0])
            to_port = length(port_parts) > 1 ? tonumber(port_parts[1]) : tonumber(port_parts[0])
            description = "Allow access from ${aws_entry.rule.source.account_id} (${aws_entry.rule.request_id})"
            rule_tags = {
              RequestID = aws_entry.rule.request_id
              SourceAccountID = aws_entry.rule.source.account_id
              SourceVPC = aws_entry.rule.source.vpc_id
              SourceRegion = aws_entry.rule.source.region
              EnablePaloInspection = tostring(aws_entry.rule.enable_palo_inspection)
              AppID = coalesce(aws_entry.rule.appid, "")
              URL = coalesce(aws_entry.rule.url, "")
            }
          }
        }
        
        # Palo Alto Rules: Group by protocol + port + appid + url
        palo_rules = {
          for palo_key in distinct([
            for entry in local.consumer_rule_entries :
            entry.palo_key
            if entry.sg_key == sg_key && entry.region == region
          ]) : palo_key => {
            # Get representative entry for this Palo grouping
            palo_entry = [
              for entry in local.consumer_rule_entries :
              entry
              if entry.sg_key == sg_key && entry.region == region && entry.palo_key == palo_key
            ][0]
            
            # Collect all source IPs for this grouping
            source_ips = distinct([
              for entry in local.consumer_rule_entries :
              entry.cidr
              if entry.sg_key == sg_key && entry.region == region && entry.palo_key == palo_key
            ])
            
            protocol = palo_entry.rule.protocol
            port = palo_entry.rule.port
            appid = coalesce(palo_entry.rule.appid, "any")
            url = palo_entry.rule.url != null && palo_entry.rule.url != "" ? palo_entry.rule.url : null
            enable_palo_inspection = palo_entry.rule.enable_palo_inspection
            request_id = palo_entry.rule.request_id
          }
        }
        
        # Overall Palo Alto settings
        enable_palo_inspection = ref_entry.rule.enable_palo_inspection
        name_prefix = ref_entry.policy.security_group.thirdpartyName
      }
    }
  }
  
  # Similar structure for provider rules (if needed)
  provider_rule_entries = flatten([
    for file, policy in local.provider_policies : [
      for rule_idx, rule in policy.rules : [
        for cidr in rule.destination.ips : {
          sg_key = "${policy.security_group.internalAppID}-${policy.security_group.region}"
          region = policy.security_group.region
          policy = policy
          rule = rule
          cidr = cidr
          aws_key = "${cidr}-${rule.protocol}-${rule.port}"
          palo_key = "${rule.protocol}-${rule.port}-${coalesce(rule.appid, "any")}-${rule.url != null && rule.url != "" ? rule.url : "any"}"
        }
      ]
    ]
  ])
  
  provider_sgs_by_region = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for entry in local.provider_rule_entries :
        entry.sg_key
        if entry.region == region
      ]) : sg_key => {
        ref_entry = [
          for entry in local.provider_rule_entries :
          entry
          if entry.sg_key == sg_key && entry.region == region
        ][0]
        
        region = region
        sg_name = "pl-provider-${ref_entry.policy.security_group.internalAppID}-${region}"
        sg_description = "Security group for ${ref_entry.policy.security_group.internalAppID} PrivateLink provider"
        vpc_id = ref_entry.policy.security_group.vpc_id
        tags = {
          InternalAppID = ref_entry.policy.security_group.internalAppID
          ServiceType = "privatelink-provider"
          RequestID = ref_entry.policy.security_group.request_id
        }
        
        aws_rules = {
          for aws_key in distinct([
            for entry in local.provider_rule_entries :
            entry.aws_key
            if entry.sg_key == sg_key && entry.region == region
          ]) : aws_key => {
            aws_entry = [
              for entry in local.provider_rule_entries :
              entry
              if entry.sg_key == sg_key && entry.region == region && entry.aws_key == aws_key
            ][0]
            
            protocol = aws_entry.rule.protocol
            port = aws_entry.rule.port
            cidr = aws_entry.cidr
            port_parts = split("-", aws_entry.rule.port)
            from_port = tonumber(port_parts[0])
            to_port = length(port_parts) > 1 ? tonumber(port_parts[1]) : tonumber(port_parts[0])
            description = "Allow access to backend (${aws_entry.rule.request_id})"
            rule_tags = {
              RequestID = aws_entry.rule.request_id
              EnablePaloInspection = tostring(aws_entry.rule.enable_palo_inspection)
              AppID = coalesce(aws_entry.rule.appid, "")
              URL = coalesce(aws_entry.rule.url, "")
            }
          }
        }
      }
    }
  }
}