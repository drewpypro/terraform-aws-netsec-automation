# locals {
#   policy_files = fileset("${path.module}/policies", "*-policy.json")

#   policies = {
#     for file in local.policy_files :
#     trimsuffix(file, "-policy.json") => jsondecode(file("${path.module}/policies/${file}"))
#   }

#   grouped_policies = {
#     for key, policy in local.policies :
#     "${policy.tags.Thirdparty}-${policy.tags.ServiceType}-${policy.region}" => policy
#   }
# }


# module "consumer_us_east_1" {
#   source = "./modules/consumer"
#   providers = { 
#     aws = aws.us_east_1
#     panos = panos
#   }
#   for_each = local.grouped_policies

#   sg_name     = each.value.security_group_name
#   vpc_id      = module.vpc_us_west_2.vpc_id
#   region      = each.value.region
#   tags        = each.value.tags
#   aws_rules   = each.value.aws_rules
#   palo_rules  = each.value.palo_rules

#   depends_on = [module.vpc_us_east_1]
# }

