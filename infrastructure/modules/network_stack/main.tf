# modules/network_stack/main.tf

locals {
  sg_raw     = yamldecode(file("${var.policies_path}/sgs.yaml"))
  rules_raw  = yamldecode(file("${var.policies_path}/rules.yaml"))

  security_groups = {
    for req in local.sg_raw.requests :
    "${req.thirdpartyName}-${req.thirdpartyId}" => {
      name        = "thirdparty-${req.thirdpartyName}-${req.thirdpartyId}-${var.region}"
      vpc_id      = aws_vpc.regional.id
      description = trimspace(req.business_justification)
      region      = var.region
      tags = {
        Name         = "thirdparty-${req.thirdpartyName}-${req.thirdpartyId}-${var.region}"
        ThirdParty   = req.thirdpartyName
        ThirdPartyId = req.thirdpartyId
        RequestID    = req.request_id
      }
    }
  }

  sg_rules = flatten([
    for req in local.rules_raw.requests : concat(
      [
        for sg_id in coalesce(req.source.security_group_ids, []) : {
          name                      = "${sg_id}-egress-${req.protocol}-${req.port}-${try(req.destination.security_group_ids[0], replace(req.destination.ips[0], "/", "_"))}"
          direction                 = "egress"
          security_group_id         = sg_id
          ip_protocol               = req.protocol == "any" ? "-1" : req.protocol
          from_port                 = req.port == "any" ? null : tonumber(req.port)
          to_port                   = req.port == "any" ? null : tonumber(req.port)
          cidr_ipv4                 = length(coalesce(req.destination.ips, [])) > 0 && length(coalesce(req.destination.security_group_ids, [])) == 0 ? req.destination.ips[0] : null
          referenced_security_group = length(coalesce(req.destination.security_group_ids, [])) > 0 ? req.destination.security_group_ids[0] : null
          description               = trimspace(req.business_justification)
          region                    = var.region
        }
      ],
      [
        for sg_id in coalesce(req.destination.security_group_ids, []) : {
          name                      = "${sg_id}-ingress-${req.protocol}-${req.port}-${try(req.source.security_group_ids[0], replace(req.source.ips[0], "/", "_"))}"
          direction                 = "ingress"
          security_group_id         = sg_id
          ip_protocol               = req.protocol == "any" ? "-1" : req.protocol
          from_port                 = req.port == "any" ? null : tonumber(req.port)
          to_port                   = req.port == "any" ? null : tonumber(req.port)
          cidr_ipv4                 = length(coalesce(req.source.ips, [])) > 0 && length(coalesce(req.source.security_group_ids, [])) == 0 ? req.source.ips[0] : null
          referenced_security_group = length(coalesce(req.source.security_group_ids, [])) > 0 ? req.source.security_group_ids[0] : null
          description               = trimspace(req.business_justification)
          region                    = var.region
        }
      ]
    )
  ])

  palo_rules = [
    for req in local.rules_raw.requests : {
      name            = "palo-${try(req.thirdPartyName, "unknown")}-${try(req.thirdpartyID, "na")}-${req.protocol}-${req.port}-${replace(try(req.source.ips[0], "any"), "/", "_")}_to_${replace(try(req.destination.ips[0], "any"), "/", "_")}"
      source_ip       = try(req.source.ips[0], "any")
      destination_ip  = try(req.destination.ips[0], "any")
      appid           = req.appid
      description     = trimspace(req.business_justification)
      region          = var.region
    } if try(req.enable_palo_inspection, false)
  ]
}

resource "aws_vpc" "regional" {
  provider = aws

  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${var.region}"
  }
}

resource "aws_security_group" "thirdparty_sg" {
  for_each = local.security_groups

  provider    = aws
  name        = each.value.name
  description = each.value.description
  vpc_id      = each.value.vpc_id
  tags        = each.value.tags
}

resource "aws_vpc_security_group_ingress_rule" "from_yaml" {
  for_each = {
    for rule in local.sg_rules : rule.name => rule if rule.direction == "ingress"
  }

  provider = aws

  security_group_id            = each.value.security_group_id
  ip_protocol                  = each.value.ip_protocol
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  cidr_ipv4                    = each.value.referenced_security_group == null ? each.value.cidr_ipv4 : null
  referenced_security_group_id = each.value.referenced_security_group != null ? each.value.referenced_security_group : null

  description = each.value.description
}

resource "aws_vpc_security_group_egress_rule" "from_yaml" {
  for_each = {
    for rule in local.sg_rules : rule.name => rule if rule.direction == "egress"
  }

  provider = aws

  security_group_id            = each.value.security_group_id
  ip_protocol                  = each.value.ip_protocol
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  cidr_ipv4                    = each.value.referenced_security_group == null ? each.value.cidr_ipv4 : null
  referenced_security_group_id = each.value.referenced_security_group != null ? each.value.referenced_security_group : null

  description = each.value.description
}

resource "panos_security_policy" "from_yaml" {
  for_each = {
    for rule in local.palo_rules : rule.name => rule
  }

  provider = panos

  rule {
    name                    = each.value.name
    source_zones            = ["any"]
    source_addresses        = [each.value.source_ip]
    source_users            = ["any"]
    destination_zones       = ["any"]
    destination_addresses   = [each.value.destination_ip]
    applications            = [each.value.appid]
    services                = ["application-default"]
    categories              = ["any"]
    action                  = "allow"
    description             = each.value.description
  }
}
