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

# Flatten aws_rules to create one rule per CIDR
locals {
  flattened_rules = flatten([
    for rule_key, rule in var.aws_rules : [
      for cidr_idx, cidr in rule.cidrs : {
        key = "${rule_key}-${cidr_idx}"
        protocol = rule.protocol
        port = rule.port
        cidr = cidr
        description = rule.description
        rule_tags = rule.rule_tags
      }
    ]
  ])
}

# Create ingress rules - one per CIDR
resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = {
    for rule in local.flattened_rules :
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