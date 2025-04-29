locals {
  raw = yamldecode(file("${path.module}/policies/palo_access.yaml"))

  sg_rules = flatten([
    for req in local.raw.requests : concat(
      [
        for sg_id in coalesce(req.source.security_group_ids, []) : {
          name = "${local.raw.request_id}-egress-${sg_id}-${req.protocol}-${req.port}-${try(req.destination.security_group_ids[0], replace(req.destination.ips[0], "/", "_"))}"
          direction                 = "egress"
          security_group_id         = sg_id
          ip_protocol               = req.protocol == "any" ? "-1" : req.protocol
          from_port                 = req.port == "any" ? null : tonumber(req.port)
          to_port                   = req.port == "any" ? null : tonumber(req.port)
          cidr_ipv4                 = length(coalesce(req.destination.ips, [])) > 0 && length(coalesce(req.destination.security_group_ids, [])) == 0 ? req.destination.ips[0] : null
          referenced_security_group = length(coalesce(req.destination.security_group_ids, [])) > 0 ? req.destination.security_group_ids[0] : null
          description               = trimspace(req.business_justification)
        }
      ],
      [
        for sg_id in coalesce(req.destination.security_group_ids, []) : {
          name = "${local.raw.request_id}-ingress-${sg_id}-${req.protocol}-${req.port}-${try(req.source.security_group_ids[0], replace(req.source.ips[0], "/", "_"))}"
          direction                 = "ingress"
          security_group_id         = sg_id
          ip_protocol               = req.protocol == "any" ? "-1" : req.protocol
          from_port                 = req.port == "any" ? null : tonumber(req.port)
          to_port                   = req.port == "any" ? null : tonumber(req.port)
          cidr_ipv4                 = length(coalesce(req.source.ips, [])) > 0 && length(coalesce(req.source.security_group_ids, [])) == 0 ? req.source.ips[0] : null
          referenced_security_group = length(coalesce(req.source.security_group_ids, [])) > 0 ? req.source.security_group_ids[0] : null
          description               = trimspace(req.business_justification)
        }
      ]
    )
  ])

  palo_rules = [
    for req in local.raw.requests : {
      name            = "${local.raw.request_id}-palo-${req.protocol}-${req.port}-${replace(try(req.source.ips[0], "any"), "/", "_")}-${replace(try(req.destination.ips[0], "any"), "/", "_")}"
      source_ip       = try(req.source.ips[0], "any")
      destination_ip  = try(req.destination.ips[0], "any")
      appid           = req.appid
      description     = trimspace(req.business_justification)
    } if try(req.enable_palo_inspection, false)
  ]
}
