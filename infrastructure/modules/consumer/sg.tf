# Create the consumer security group
resource "aws_security_group" "this" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = var.vpc_id
  
  tags = var.tags
  
  lifecycle {
    create_before_destroy = true
  }
}

# Create ingress rules for the consumer security group
resource "aws_vpc_security_group_ingress_rule" "rule" {
  for_each = {
    for idx, rule in var.ingress_rules :
    rule.key => rule
  }
  
  security_group_id = aws_security_group.this.id
  ip_protocol       = each.value.protocol
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = each.value.cidr
  description       = each.value.description
  
  tags = each.value.rule_tags
}