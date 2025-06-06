# Create consumer security groups for us-east-1 region
module "consumer_sg_us_east_1" {
  source = "./modules/consumer"
  
  for_each = try(local.consumer_rules_by_region["us-east-1"], {})
  
  providers = { 
    aws = aws.us_east_1
  }
  
  # Security group settings
  region = "us-east-1"
  security_group_name = each.value.sg_definition.sg_name
  security_group_description = each.value.sg_definition.sg_description
  vpc_id = each.value.sg_definition.policy.security_group.vpc_id
  tags = each.value.sg_definition.tags
  
  # Pass all rules for this security group
  sg_rules = each.value.rules
  
  # Palo Alto settings (aggregate values)
  enable_palo_inspection = try(local.consumer_palo_rules_by_region["us-east-1"][each.key].enable_palo_inspection, false)
  palo_rule_name = try(local.consumer_palo_rules_by_region["us-east-1"][each.key].palo_rule_name, "")
  palo_source_cidrs = try(local.consumer_palo_rules_by_region["us-east-1"][each.key].all_source_cidrs, [])
  palo_appids = try(local.consumer_palo_rules_by_region["us-east-1"][each.key].all_appids, [])
  palo_urls = try(local.consumer_palo_rules_by_region["us-east-1"][each.key].all_urls, [])
  palo_description = try(local.consumer_palo_rules_by_region["us-east-1"][each.key].description, "")
  name_prefix = each.value.sg_definition.policy.security_group.thirdpartyName
  request_ids = try(local.consumer_palo_rules_by_region["us-east-1"][each.key].all_request_ids, [])
}

# Create consumer security groups for us-west-2 region
module "consumer_sg_us_west_2" {
  source = "./modules/consumer"
  
  for_each = try(local.consumer_rules_by_region["us-west-2"], {})
  
  providers = { 
    aws = aws.us_west_2
  }
  
  # Security group settings
  region = "us-west-2"
  security_group_name = each.value.sg_definition.sg_name
  security_group_description = each.value.sg_definition.sg_description
  vpc_id = each.value.sg_definition.policy.security_group.vpc_id
  tags = each.value.sg_definition.tags
  
  # Pass all rules for this security group
  sg_rules = each.value.rules
  
  # Palo Alto settings (aggregate values)
  enable_palo_inspection = try(local.consumer_palo_rules_by_region["us-west-2"][each.key].enable_palo_inspection, false)
  palo_rule_name = try(local.consumer_palo_rules_by_region["us-west-2"][each.key].palo_rule_name, "")
  palo_source_cidrs = try(local.consumer_palo_rules_by_region["us-west-2"][each.key].all_source_cidrs, [])
  palo_appids = try(local.consumer_palo_rules_by_region["us-west-2"][each.key].all_appids, [])
  palo_urls = try(local.consumer_palo_rules_by_region["us-west-2"][each.key].all_urls, [])
  palo_description = try(local.consumer_palo_rules_by_region["us-west-2"][each.key].description, "")
  name_prefix = each.value.sg_definition.policy.security_group.thirdpartyName
  request_ids = try(local.consumer_palo_rules_by_region["us-west-2"][each.key].all_request_ids, [])
}

# Create provider security groups for us-east-1 region
module "provider_sg_us_east_1" {
  source = "./modules/provider"
  
  for_each = try(local.provider_sg_rules["us-east-1"], {})
  
  providers = { 
    aws = aws.us_east_1
  }
  
  # Take values from the first rule in the group
  # Security group settings
  region = "us-east-1"
  security_group_name = each.key  # This is the sg_name
  security_group_description = each.value[0].sg_description
  vpc_id = each.value[0].policy.security_group.vpc_id
  tags = each.value[0].tags
  
  # Take the first rule's details
  protocol = each.value[0].rule.protocol
  from_port = each.value[0].rule.port
  to_port = each.value[0].rule.port
  destination_cidrs = [for rule in each.value : rule.cidr]
  source_cidrs = [""]
  description = "Allow access to backend (${each.value[0].rule.request_id})"
  rule_tags = each.value[0].rule_tags
  
  # Palo Alto settings
  enable_palo_inspection = false
  name_prefix = each.value[0].policy.security_group.internalAppID
  request_id = each.value[0].rule.request_id
  appid = each.value[0].rule.appid
  url = each.value[0].rule.url
}

# Create provider security groups for us-west-2 region
module "provider_sg_us_west_2" {
  source = "./modules/provider"
  
  for_each = try(local.provider_sg_rules["us-west-2"], {})
  
  providers = { 
    aws = aws.us_west_2
  }
  
  # Take values from the first rule in the group
  # Security group settings
  region = "us-west-2"
  security_group_name = each.key  # This is the sg_name
  security_group_description = each.value[0].sg_description
  vpc_id = each.value[0].policy.security_group.vpc_id
  tags = each.value[0].tags
  
  # Take the first rule's details
  protocol = each.value[0].rule.protocol
  from_port = each.value[0].rule.port
  to_port = each.value[0].rule.port
  destination_cidrs = [for rule in each.value : rule.cidr]
  source_cidrs = [""]
  description = "Allow access to backend (${each.value[0].rule.request_id})"
  rule_tags = each.value[0].rule_tags
  
  # Palo Alto settings
  enable_palo_inspection = false
  name_prefix = each.value[0].policy.security_group.internalAppID
  request_id = each.value[0].rule.request_id
  appid = each.value[0].rule.appid
  url = each.value[0].rule.url
}