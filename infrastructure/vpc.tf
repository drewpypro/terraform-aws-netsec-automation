# resource "aws_vpc" "regional_vpc" {
#   for_each = toset(var.regions)

#   cidr_block = var.vpc_cidr_block[each.key]
#   tags = {
#     Name = "vpc-${each.key}"
#   }

#   provider = local.aws_provider_alias_map[each.value.region]

# }

# output "vpc_ids" {
#   description = "VPC ID by region"
#   value = {
#     for region, vpc in aws_vpc.regional_vpc :
#     region => vpc.id
#   }
# }