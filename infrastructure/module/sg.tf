resource "aws_security_group" "thirdparty_sg" {
  name        = var.sg.name
  description = var.sg.description
  vpc_id      = var.sg.vpc_id
  tags        = var.sg.tags
}

resource "aws_vpc_security_group_ingress_rule" "rule" {
  count = length(var.ingress_rules)

  security_group_id = aws_security_group.thirdparty_sg.id
  ip_protocol       = var.ingress_rules[count.index].ip_protocol
  from_port         = var.ingress_rules[count.index].from_port
  to_port           = var.ingress_rules[count.index].to_port

  cidr_ipv4                    = var.ingress_rules[count.index].referenced_security_group == null ? var.ingress_rules[count.index].cidr_ipv4 : null
  referenced_security_group_id = var.ingress_rules[count.index].referenced_security_group != null ? var.ingress_rules[count.index].referenced_security_group : null

  description = var.ingress_rules[count.index].description
}

resource "aws_vpc_security_group_egress_rule" "rule" {
  count = length(var.egress_rules)

  security_group_id = aws_security_group.thirdparty_sg.id
  ip_protocol       = var.egress_rules[count.index].ip_protocol
  from_port         = var.egress_rules[count.index].from_port
  to_port           = var.egress_rules[count.index].to_port

  cidr_ipv4                    = var.egress_rules[count.index].referenced_security_group == null ? var.egress_rules[count.index].cidr_ipv4 : null
  referenced_security_group_id = var.egress_rules[count.index].referenced_security_group != null ? var.egress_rules[count.index].referenced_security_group : null

  description = var.egress_rules[count.index].description
}
