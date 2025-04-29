locals {
  raw = yamldecode(file("${path.module}/policies/palo_access.yaml"))

  ingress_rules = flatten([
    for i, req in local.raw.requests : [
      for sg_id in try(req.destination.security_group_ids, []) : {
        name        = "${local.raw.request_id}-ingress-${i}"
        direction   = "ingress"
        sg_id       = sg_id
        ip_protocol = req.protocol == "any" ? "-1" : req.protocol
        from_port   = req.port == "any" ? null : tonumber(req.port)
        to_port     = req.port == "any" ? null : tonumber(req.port)
        cidr_ipv4   = try(req.source.ips[0], null)
        justification = trimspace(req.business_justification)
      }
    ]
  ])

  egress_rules = flatten([
    for i, req in local.raw.requests : [
      for sg_id in try(req.source.security_group_ids, []) : {
        name        = "${local.raw.request_id}-egress-${i}"
        direction   = "egress"
        sg_id       = sg_id
        ip_protocol = req.protocol == "any" ? "-1" : req.protocol
        from_port   = req.port == "any" ? null : tonumber(req.port)
        to_port     = req.port == "any" ? null : tonumber(req.port)
        cidr_ipv4   = try(req.destination.ips[0], null)
        justification = trimspace(req.business_justification)
      }
    ]
  ])

  rules = concat(local.ingress_rules, local.egress_rules)
}
