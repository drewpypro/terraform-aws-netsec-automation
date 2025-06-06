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

# # Create ingress rules for each protocol/port combination
# resource "aws_vpc_security_group_ingress_rule" "this" {
#   for_each = var.sg_rules

#   security_group_id = aws_security_group.this.id
#   ip_protocol       = each.value.protocol
#   from_port         = each.value.port
#   to_port           = each.value.port
#   cidr_ipv4         = join(",", each.value.source_cidrs)
#   description       = "Allow ${each.value.protocol}/${each.value.port} from ${each.value.source_account_id} (${join(",", each.value.request_ids)})"
  
#   tags = each.value.rule_tags
# }

# Alternative approach if the above doesn't work with comma-separated CIDRs
# You might need to create separate rules for each CIDR
resource "aws_vpc_security_group_ingress_rule" "individual_cidrs" {
  for_each = {
    for rule_key, rule in var.sg_rules : 
    rule_key => {
      for cidr in rule.source_cidrs :
      "${rule_key}-${cidr}" => {
        protocol    = rule.protocol
        port        = rule.port
        cidr        = cidr
        rule_tags   = rule.rule_tags
        request_ids = rule.request_ids
        source_account_id = rule.source_account_id
      }
    }
  }

  security_group_id = aws_security_group.this.id
  ip_protocol       = each.value.protocol
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = each.value.cidr
  description       = "Allow ${each.value.protocol}/${each.value.port} from ${each.value.source_account_id} (${join(",", each.value.request_ids)})"
  
  tags = each.value.rule_tags
}

# Note: Use either the first approach or the second approach, not both.
# The first approach attempts to use comma-separated CIDRs in a single rule.
# The second approach creates individual rules for each CIDR.
# Test which one works with your AWS provider version.