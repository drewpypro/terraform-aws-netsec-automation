locals {
  raw = yamldecode(file("${path.module}/policies/palo_access.yaml"))

  rules = flatten([
    for i, req in local.raw.requests : [
      # Ingress from IP to SG
      for sg_id in lookup(req.destination, "security_group_ids", []) : {
        name            = "${local.raw.request_id}-ingress-${i}"
        direction       = "ingress"
        sg_id           = sg_id
        description = req.business_justification
        ip_protocol     = req.protocol == "any" ? "-1" : req.protocol
        from_port       = req.port == "any" ? null : tonumber(req.port)
        to_port         = req.port == "any" ? null : tonumber(req.port)
        cidr_ipv4       = try(req.source.ips[0], null)
      }
    ] ++ [
      # Egress from SG to IP
      for sg_id in lookup(req.source, "security_group_ids", []) : {
        name            = "${local.raw.request_id}-egress-${i}"
        direction       = "egress"
        sg_id           = sg_id
        description = req.business_justification
        ip_protocol     = req.protocol == "any" ? "-1" : req.protocol
        from_port       = req.port == "any" ? null : tonumber(req.port)
        to_port         = req.port == "any" ? null : tonumber(req.port)
        cidr_ipv4       = try(req.destination.ips[0], null)
      }
    ]
  ])
}
