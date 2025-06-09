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
  
  # Flatten all consumer rules into individual entries with all needed data
  consumer_rule_entries = flatten([
    for file, policy in local.consumer_policies : [
      for rule_idx, rule in policy.rules : [
        for cidr in rule.source.ips : {
          # Identifiers
          sg_key = "${policy.security_group.thirdpartyName}-${policy.security_group.region}"
          region = policy.security_group.region
          aws_key = "${cidr}-${rule.protocol}-${rule.port}"
          palo_key = "${rule.protocol}-${rule.port}-${coalesce(rule.appid, "any")}-${rule.url != null && rule.url != "" ? rule.url : "any"}"
          
          # Policy data (flattened for easy access)
          thirdpartyName = policy.security_group.thirdpartyName
          serviceName = policy.security_group.serviceName
          vpc_id = policy.security_group.vpc_id
          thirdPartyID = policy.security_group.thirdPartyID
          policy_request_id = policy.security_group.request_id
          
          # Rule data
          rule_request_id = rule.request_id
          protocol = rule.protocol
          port = rule.port
          cidr = cidr
          appid = rule.appid
          url = rule.url
          enable_palo_inspection = rule.enable_palo_inspection
          source_account_id = rule.source.account_id
          source_vpc_id = rule.source.vpc_id
          source_region = rule.source.region
        }
      ]
    ]
  ])
  
  # Create reference data for each security group
  consumer_sg_refs = {
    for region in local.regions : region => {
      for sg_key in distinct([
        for entry in local.consumer_rule_entries :
        entry.sg_key
        if entry.region == region
      ]) : sg_key => [
        for entry in local.consumer_rule_entries :
        entry
        if entry.sg_key == sg_key && entry.region == region
      ][0] # Take first entry as reference
    }
  }
  
  # Group consumer security groups by region
  consumer_sgs_by_region = {
    for region in local.regions : region => {
      for sg_key in keys(try(local.consumer_sg_refs[region], {})) : sg_key => {
        # Get reference data
        ref = local.consumer_sg_refs[region][sg_key]
        
        # Basic SG info
        region = region
        sg_name = "${lower(ref.thirdpartyName)}-${replace(ref.serviceName, "com.amazonaws.vpce.", "")}-${region}-sg"
        sg_description = "Security group for ${ref.thirdpartyName} PrivateLink (${ref.serviceName})"
        vpc_id = ref.vpc_id
        service_name = ref.serviceName
        tags = {
          ThirdPartyID = ref.thirdPartyID
          ThirdPartyName = ref.thirdpartyName
          ServiceType = "privatelink-consumer"
          RequestID = ref.policy_request_id
          ServiceName = ref.serviceName
        }
        
        # AWS Rules: Group by cidr + protocol + port
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
            
            # Parse port range
            port_parts = split("-", aws_entry.port)
            from_port = tonumber(port_parts[0])
            to_port = length(port_parts) > 1 ? tonumber(port_parts[1]) : tonumber(port_parts[0])
            
            protocol = aws_entry.protocol
            port = aws_entry.port
            cidr = aws_entry.cidr
            description = "Allow access from ${aws_entry.source_account_id} (${aws_entry.rule_request_id})"
            rule_tags = {
              RequestID = aws_entry.rule_request_id
              SourceAccountID = aws_entry.source_account_id
              SourceVPC = aws_entry.source_vpc_id
              SourceRegion = aws_entry.source_region
              EnablePaloInspection = tostring(aws_entry.enable_palo_inspection)
              AppID = coalesce(aws_entry.appid, "")
              URL = coalesce(aws_entry.url, "")
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
            
            protocol = palo_entry.protocol
            port = palo_entry.port
            appid = coalesce(palo_entry.appid, "any")
            url = palo_entry.url != null && palo_entry.url != "" ? palo_entry.url : null
            enable_palo_inspection = palo_entry.enable_palo_inspection
            request_id = palo_entry.rule_request_id
          }
        }
        
        # Overall Palo Alto settings
        enable_palo_inspection = ref.enable_palo_inspection
        name_prefix = ref.thirdpartyName
      }
    }
  }
}