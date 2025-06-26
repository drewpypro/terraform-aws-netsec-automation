
resource "aws_security_group" "consumer_sg" {
  name        = var.sg_name
  vpc_id      = var.vpc_id
  description = "Managed by Terraform"
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  count                    = length(var.aws_rules)
  security_group_id        = aws_security_group.consumer_sg.id
  cidr_ipv4                = var.aws_rules[count.index].cidr
  from_port                = var.aws_rules[count.index].from_port
  to_port                  = var.aws_rules[count.index].to_port
  ip_protocol              = var.aws_rules[count.index].protocol
  description              = var.aws_rules[count.index].description
}
