output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.this.id
}

output "security_group_name" {
  description = "Name of the security group"
  value       = aws_security_group.this.name
}

output "rule_id" {
  description = "ID of the ingress rule"
  value       = aws_vpc_security_group_ingress_rule.this.id
}

output "palo_rule_name" {
  description = "Name of the Palo Alto rule, if created"
  value       = var.enable_palo_inspection ? panos_security_policy.rule[0].rule[0].name : ""
}