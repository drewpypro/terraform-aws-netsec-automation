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

resource "aws_vpc_security_group_ingress_rule" "from_yaml" {
  for_each = {
    for rule in local.rules : rule.name => rule
    if rule.direction == "ingress" && rule.cidr_ipv4 != null
  }

  security_group_id = each.value.sg_id
  ip_protocol       = each.value.ip_protocol
  from_port         = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.ip_protocol == "-1" ? null : each.value.to_port
  cidr_ipv4         = each.value.cidr_ipv4
  description       = each.value.justification
}

resource "aws_vpc_security_group_egress_rule" "from_yaml" {
  for_each = {
    for rule in local.rules : rule.name => rule
    if rule.direction == "egress" && rule.cidr_ipv4 != null
  }

  security_group_id = each.value.sg_id
  ip_protocol       = each.value.ip_protocol
  from_port         = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.ip_protocol == "-1" ? null : each.value.to_port
  cidr_ipv4         = each.value.cidr_ipv4
  description       = each.value.justification
}
