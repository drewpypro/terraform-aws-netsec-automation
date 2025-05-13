# modules/network_stack/outputs.tf

output "vpc_id" {
  description = "The ID of the regional VPC"
  value       = aws_vpc.regional.id
}

output "security_group_ids" {
  description = "Map of third-party security group IDs"
  value = {
    for k, v in aws_security_group.thirdparty_sg : k => v.id
  }
}

output "palo_rule_names" {
  description = "List of Palo Alto rule names applied in this region"
  value       = [for k in panos_security_policy.from_yaml : k]
}
