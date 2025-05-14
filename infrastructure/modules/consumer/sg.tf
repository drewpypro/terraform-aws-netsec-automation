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

# Create ingress rule for the consumer security group
resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = toset(var.source_cidrs)

  security_group_id = aws_security_group.this.id
  ip_protocol       = var.protocol
  from_port         = var.from_port
  to_port           = var.to_port
  cidr_ipv4         = each.value
  description       = var.description
  
  tags = var.rule_tags
}
