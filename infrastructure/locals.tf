locals {
  
  aws_provider_alias_map = {
    "us-west-2" = aws.us-west-2
    "us-east-1" = aws.us-east-1
  }
  
  flat_security_groups = merge([
    for region in var.regions : {
      for req in yamldecode(file("${path.module}/policies/${region}/sgs.yaml")).requests :
      "${region}-${req.thirdpartyName}-${req.thirdpartyId}" => {
        name        = "thirdparty-${req.thirdpartyName}-${req.thirdpartyId}-${region}"
        vpc_id      = req.vpc_id
        description = trimspace(req.business_justification)
        region      = region
        tags = {
          Name         = "thirdparty-${req.thirdpartyName}-${req.thirdpartyId}-${region}"
          ThirdParty   = req.thirdpartyName
          ThirdPartyId = req.thirdpartyId
          RequestID    = req.request_id
        }
      }
    }
  ]...)

  flat_sg_rules = flatten([
    for region in var.regions : [
      for req in yamldecode(file("${path.module}/policies/${region}/rules.yaml")).requests : concat(
        [
          for sg_id in coalesce(req.source.security_group_ids, []) : {
            name                      = "${region}-${sg_id}-egress-${req.protocol}-${req.port}-${try(req.destination.security_group_ids[0], replace(req.destination.ips[0], "/", "_"))}"
            direction                 = "egress"
            security_group_id        = sg_id
            ip_protocol               = req.protocol == "any" ? "-1" : req.protocol
            from_port                 = req.port == "any" ? null : tonumber(req.port)
            to_port                   = req.port == "any" ? null : tonumber(req.port)
            cidr_ipv4                 = length(coalesce(req.destination.ips, [])) > 0 && length(coalesce(req.destination.security_group_ids, [])) == 0 ? req.destination.ips[0] : null
            referenced_security_group = length(coalesce(req.destination.security_group_ids, [])) > 0 ? req.destination.security_group_ids[0] : null
            description               = trimspace(req.business_justification)
            region                    = region
          }
        ],
        [
          for sg_id in coalesce(req.destination.security_group_ids, []) : {
            name                      = "${region}-${sg_id}-ingress-${req.protocol}-${req.port}-${try(req.source.security_group_ids[0], replace(req.source.ips[0], "/", "_"))}"
            direction                 = "ingress"
            security_group_id        = sg_id
            ip_protocol               = req.protocol == "any" ? "-1" : req.protocol
            from_port                 = req.port == "any" ? null : tonumber(req.port)
            to_port                   = req.port == "any" ? null : tonumber(req.port)
            cidr_ipv4                 = length(coalesce(req.source.ips, [])) > 0 && length(coalesce(req.source.security_group_ids, [])) == 0 ? req.source.ips[0] : null
            referenced_security_group = length(coalesce(req.source.security_group_ids, [])) > 0 ? req.source.security_group_ids[0] : null
            description               = trimspace(req.business_justification)
            region                    = region
          }
        ]
      )
    ]
  ])

  flat_palo_rules = merge([
    for region in var.regions : {
      for req in yamldecode(file("${path.module}/policies/${region}/rules.yaml")).requests :
      "${region}-palo-${try(req.thirdPartyName, "unknown")}-${try(req.thirdpartyID, "na")}-${req.protocol}-${req.port}" => {
        name           = "palo-${try(req.thirdPartyName, "unknown")}-${try(req.thirdpartyID, "na")}-${req.protocol}-${req.port}"
        source_ip      = try(req.source.ips[0], "any")
        destination_ip = try(req.destination.ips[0], "any")
        appid          = req.appid
        description    = trimspace(req.business_justification)
        region         = region
      } if try(req.enable_palo_inspection, false)
    }
  ]...)
}