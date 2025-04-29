locals {
  raw = yamldecode(file("${path.module}/policies/palo_access.yaml"))

  ingress_rules = flatten([
    for req in local.raw.requests : [
      for dest_sg in try(req.destination.security_group_ids, []) : {
        name        = "${local.raw.request_id}-ingress-${dest_sg}-${req.protocol}-${req.port}"
        direction   = "ingress"
        sg_id       = dest_sg
        ip_protocol = req.protocol == "any" ? "-1" : req.protocol
        from_port   = req.port == "any" ? null : tonumber(req.port)
        to_port     = req.port == "any" ? null : tonumber(req.port)
        referenced_security_group_id = (try(req.source.security_group_ids, null) != null && !try(req.enable_palo_inspection, false)) ? req.source.security_group_ids[0] : "null"
        cidr_ipv4   = (try(req.source.ips, null) != null && !try(req.enable_palo_inspection, false)) ? req.source.ips[0] : null
        justification = trimspace(req.business_justification)
      }
    ]
  ])

  egress_rules = flatten([
    for req in local.raw.requests : [
      for src_sg in try(req.source.security_group_ids, []) : {
        name        = "${local.raw.request_id}-egress-${src_sg}-${req.protocol}-${req.port}"
        direction   = "egress"
        sg_id       = src_sg
        ip_protocol = req.protocol == "any" ? "-1" : req.protocol
        from_port   = req.port == "any" ? null : tonumber(req.port)
        to_port     = req.port == "any" ? null : tonumber(req.port)
        referenced_security_group_id = (try(req.destination.security_group_ids, null) != null && !try(req.enable_palo_inspection, false)) ? req.destination.security_group_ids[0] : "null"
        cidr_ipv4   = (try(req.destination.ips, null) != null && !try(req.enable_palo_inspection, false)) ? req.destination.ips[0] : null
        justification = trimspace(req.business_justification)
      }
    ]
  ])

  rules = concat(local.ingress_rules, local.egress_rules)

  palo_rules = [
    for req in local.raw.requests : {
      name            = "${local.raw.request_id}-${req.protocol}-${req.port}"
      source_ip       = can(req.source.ips[0]) ? req.source.ips[0] : "any"
      destination_ip  = can(req.destination.ips[0]) ? req.destination.ips[0] : "any"
      protocol        = req.protocol
      port            = req.port
      appid           = req.appid
      justification   = trimspace(req.business_justification)
    }
    if try(req.enable_palo_inspection, false)
  ]
}
