locals {
  policy_files_v2 = fileset("${path.module}/policies_v2", "*-policy.json")

  policies_v2 = {
    for file in local.policy_files_v2 :
    trimsuffix(file, "-policy.json") => jsondecode(file("${path.module}/policies_v2/${file}"))
  }

  grouped_policies_v2 = {
    for key, policy_v2 in local.policies_v2 :
    "${policy_v2.tags.Thirdparty}-${policy_v2.tags.ServiceType}-${policy_v2.region}" => policy_v2
  }
}

# --- Palo Objects Module ---

module "palo_objects_us_east_1" {
  source          = "./modules/palo-objects"
  service_objects = local.palo_service_objects
  tags            = local.palo_tags
  url_categories  = local.palo_url_categories_filtered
  region          = "us-east-1"
}

module "consumer_us_east_1_v2" {
  source = "./modules/consumer"
  providers = { 
    aws = aws.us_east_1
    panos = panos
  }
  for_each = local.grouped_policies_v2

  sg_name     = each.value.security_group_name
  vpc_id      = module.vpc_us_east_1.vpc_id
  region      = each.value.region
  tags        = each.value.tags
  aws_rules   = each.value.aws_rules
  palo_rules  = each.value.palo_rules

  depends_on = [module.vpc_us_east_1]
}

# Create consumer security groups for us-east-1 region
module "consumer_sg_us_east_1_v1" {
  source = "./modules/consumer-old/"
  
  for_each = try(local.consumer_sgs_by_region["us-east-1"], {})
  
  providers = { 
    aws = aws.us_east_1
    panos = panos
  }
  
  # Security group settings
  region = "us-east-1"
  security_group_name = each.value.sg_name
  security_group_description = each.value.sg_description
  vpc_id = each.value.vpc_id
  tags = each.value.tags
  service_name = each.value.tags.ServiceName
  
  # AWS security group rules (pre-processed, no loops needed in module)
  aws_rules = each.value.aws_rules
  
  # Palo Alto settings  
  enable_palo_inspection = each.value.enable_palo_inspection
  name_prefix = each.value.name_prefix
  request_id = each.value.request_id
  appid = each.value.appid
  url = each.value.url
  palo_protocols_ports = each.value.palo_protocols_ports
  palo_source_ips = each.value.palo_source_ips
  palo_rules = each.value.palo_rules

  # Inject deduped Palo Alto objects (from module)
  palo_service_objects        = module.palo_objects_us_east_1.service_names
  palo_tags                   = module.palo_objects_us_east_1.tag_names
  palo_url_categories         = module.palo_objects_us_east_1.url_category_names

  depends_on = [module.vpc_us_east_1, module.palo_objects_us_east_1]
}

