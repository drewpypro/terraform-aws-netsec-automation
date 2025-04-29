resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Empty SG for EC2"
  vpc_id      = aws_vpc.test_vpc.id

  tags = {
    Name = "app-ec2-sg"
  }

}

resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpce-sg"
  description = "Empty SG for VPC endpoint"
  vpc_id      = aws_vpc.test_vpc.id

  tags = {
    Name = "vpce-endpoint-sg"
  }

}

resource "aws_security_group" "thirdparty_vpce_sg" {
  name        = "thirdparty-vpce-sg"
  description = "Empty SG for Thirdparty PrivateLink endpoint"
  vpc_id      = aws_vpc.test_vpc.id

  tags = {
    Name = "thirdparty-vpce-sg"
  }
}

resource "aws_security_group" "paloalto_vm_sg" {
  name        = "paloalto-vm-sg"
  description = "Palo Alto VM"
  vpc_id      = aws_vpc.test_vpc.id

  tags = {
    Name = "paloalto-vm-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_referenced" {
  for_each = {
    for rule in local.rules :
    "${rule.name}-${rule.from_port}-${rule.to_port}-${rule.ip_protocol}-${rule.referenced_security_group_id}-ingress"
    => rule if rule.referenced_security_group_id != "null" && rule.cidr_ipv4 == "null" && rule.direction == "ingress"
  }

  security_group_id            = aws_security_group.sgs[each.value.sg_id].id
  from_port                    = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port                      = each.value.ip_protocol == "-1" ? null : each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  referenced_security_group_id = aws_security_group.sgs[each.value.referenced_security_group_id].id
  description                  = each.value.business_justification
}

resource "aws_vpc_security_group_ingress_rule" "ingress_cidr" {
  for_each = {
    for rule in local.rules :
    "${rule.name}-${rule.from_port}-${rule.to_port}-${rule.ip_protocol}-${rule.cidr_ipv4}-ingress"
    => rule if rule.cidr_ipv4 != "null" && rule.direction == "ingress"
  }

  security_group_id = aws_security_group.sgs[each.value.sg_id].id
  from_port         = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.ip_protocol == "-1" ? null : each.value.to_port
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = each.value.cidr_ipv4
  description       = each.value.business_justification
}

resource "aws_vpc_security_group_egress_rule" "egress_referenced" {
  for_each = {
    for rule in local.rules :
    "${rule.name}-${rule.from_port}-${rule.to_port}-${rule.ip_protocol}-${rule.referenced_security_group_id}-egress"
    => rule if rule.referenced_security_group_id != "null" && rule.cidr_ipv4 == "null" && rule.direction == "egress"
  }

  security_group_id            = aws_security_group.sgs[each.value.sg_id].id
  from_port                    = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port                      = each.value.ip_protocol == "-1" ? null : each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  referenced_security_group_id = aws_security_group.sgs[each.value.referenced_security_group_id].id
  description                  = each.value.business_justification
}

resource "aws_vpc_security_group_egress_rule" "egress_cidr" {
  for_each = {
    for rule in local.rules :
    "${rule.name}-${rule.from_port}-${rule.to_port}-${rule.ip_protocol}-${rule.cidr_ipv4}-egress"
    => rule if rule.cidr_ipv4 != "null" && rule.direction == "egress"
  }

  security_group_id = aws_security_group.sgs[each.value.sg_id].id
  from_port         = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.ip_protocol == "-1" ? null : each.value.to_port
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = each.value.cidr_ipv4
  description       = each.value.business_justification
}