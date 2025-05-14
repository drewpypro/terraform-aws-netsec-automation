# Create consumer security groups for us-east-1 region
module "consumer_sg_us_east_1" {
  source = "./modules/consumer"
  
  for_each = try(local.consumer_sg_rules["us-east-1"], {})
  
  providers = { 
    aws = aws.us_east_1
    panos = panos
  }
  
  # Take values from the first rule in the group
  # Security group settings
  security_group_name = each.key  # This is the sg_name
  security_group_description = each.value[0].sg_description
  vpc_id = each.value[0].policy.security_group.vpc_id
  tags = each.value[0].tags
  
  # Take the first rule's details
  protocol = each.value[0].rule.protocol
  from_port = each.value[0].rule.port
  to_port = each.value[0].rule.port
  source_cidrs = [for rule in each.value : rule.cidr]
  destination_cidrs = [""]
  description = "Allow access from ${each.value[0].rule.source.account_id} (${each.value[0].rule.request_id})"
  rule_tags = each.value[0].rule_tags
  
  # Palo Alto settings
  enable_palo_inspection = false
  name_prefix = each.value[0].policy.security_group.thirdpartyName
  request_id = each.value[0].rule.request_id
  appid = each.value[0].rule.appid
  url = each.value[0].rule.url
  
}

# Create provider security groups for us-east-1 region
module "provider_sg_us_east_1" {
  source = "./modules/provider"
  
  for_each = try(local.provider_sg_rules["us-east-1"], {})
  
  providers = { 
    aws = aws.us_east_1
    panos = panos
  }
  
  # Take values from the first rule in the group
  # Security group settings
  security_group_name = each.key  # This is the sg_name
  security_group_description = each.value[0].sg_description
  vpc_id = each.value[0].policy.security_group.vpc_id
  tags = each.value[0].tags
  
  # Take the first rule's details
  protocol = each.value[0].rule.protocol
  from_port = each.value[0].rule.port
  to_port = each.value[0].rule.port
  destination_cidrs = [for rule in each.value : rule.cidr]
  source_cidrs = ""
  description = "Allow access to backend (${each.value[0].rule.request_id})"
  rule_tags = each.value[0].rule_tags
  
  # Palo Alto settings
  enable_palo_inspection = false
  name_prefix = each.value[0].policy.security_group.internalAppID
  request_id = each.value[0].rule.request_id
  appid = each.value[0].rule.appid
  url = each.value[0].rule.url

}

# Create consumer security groups for us-west-2 region
module "consumer_sg_us_west_2" {
  source = "./modules/consumer"
  
  for_each = try(local.consumer_sg_rules["us-west-2"], {})
  
  providers = { 
    aws = aws.us_west_2
    panos = panos
  }
  
  # Take values from the first rule in the group
  # Security group settings
  security_group_name = each.key  # This is the sg_name
  security_group_description = each.value[0].sg_description
  vpc_id = each.value[0].policy.security_group.vpc_id
  tags = each.value[0].tags
  
  # Take the first rule's details
  protocol = each.value[0].rule.protocol
  from_port = each.value[0].rule.port
  to_port = each.value[0].rule.port
  source_cidrs = [for rule in each.value : rule.cidr]
  destination_cidrs = [""]
  description = "Allow access from ${each.value[0].rule.source.account_id} (${each.value[0].rule.request_id})"
  rule_tags = each.value[0].rule_tags
  
  # Palo Alto settings
  enable_palo_inspection = false
  name_prefix = each.value[0].policy.security_group.thirdpartyName
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
    panos = panos
  }
  
  # Take values from the first rule in the group
  # Security group settings
  security_group_name = each.key  # This is the sg_name
  security_group_description = each.value[0].sg_description
  vpc_id = each.value[0].policy.security_group.vpc_id
  tags = each.value[0].tags
  
  # Take the first rule's details
  protocol = each.value[0].rule.protocol
  from_port = each.value[0].rule.port
  to_port = each.value[0].rule.port
  destination_cidrs = [for rule in each.value : rule.cidr]
  source_cidrs = ""
  description = "Allow access to backend (${each.value[0].rule.request_id})"
  rule_tags = each.value[0].rule_tags
  
  # Palo Alto settings
  enable_palo_inspection = false
  name_prefix = each.value[0].policy.security_group.internalAppID
  request_id = each.value[0].rule.request_id
  appid = each.value[0].rule.appid
  url = each.value[0].rule.url
  
}