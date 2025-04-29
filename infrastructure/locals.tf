locals {
  raw = yamldecode(file("${path.module}/policies/palo_access.yaml"))

  ingress_rules = flatten([
    for i, req in local.raw.requests : [
      for sg_id in can(req.destination.security_group_ids) && req.destination.security_group_ids != null ? req.destination.security_group_ids : [] : {
        name        = "${local.raw.request_id}-ingress-${sg_id}-${req.protocol}-${req.port}"
        direction   = "ingress"
        sg_id       = sg_id
        ip_protocol = req.protocol == "any" ? "-1" : req.protocol
        from_port   = req.port == "any" ? null : tonumber(req.port)
        to_port     = req.port == "any" ? null : tonumber(req.port)
        cidr_ipv4   = can(req.source.ips[0]) ? req.source.ips[0] : null
        justification = trimspace(req.business_justification)
      }
    ]
  ])

  egress_rules = flatten([
    for i, req in local.raw.requests : [
      for sg_id in can(req.source.security_group_ids) && req.source.security_group_ids != null ? req.source.security_group_ids : [] : {
        name        = "${local.raw.request_id}-egress-${sg_id}-${req.protocol}-${req.port}"
        direction   = "egress"
        sg_id       = sg_id
        ip_protocol = req.protocol == "any" ? "-1" : req.protocol
        from_port   = req.port == "any" ? null : tonumber(req.port)
        to_port     = req.port == "any" ? null : tonumber(req.port)
        cidr_ipv4   = can(req.destination.ips[0]) ? req.destination.ips[0] : null
        justification = trimspace(req.business_justification)
      }
    ]
  ])

  rules = concat(local.ingress_rules, local.egress_rules)

  thirdparty_cidrs = ["100.64.0.0/23"]

  palo_rules = [
  for i, req in local.raw.requests : {
      name              = "${local.raw.request_id}-${req.protocol}-${req.port}"
      source_ip = can(req.source.ips[0]) ? req.source.ips[0] : "any"
      destination_ip    = can(req.destination.ips[0]) ? req.destination.ips[0] : "any"
      protocol          = req.protocol
      port              = req.port
      appid             = req.appid
      justification     = trimspace(req.business_justification)
  }
  if try(req.enable_palo_inspection, false)
  ]
}
