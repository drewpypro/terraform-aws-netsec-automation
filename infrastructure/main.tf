# Create consumer security groups for use1 regions
module "consumer_us_east_1" {
  source = "./modules/consumer"
  
  for_each = {
    for rule in local.consumer_rules :
    rule.key => rule
    if rule.region == "us-east-1"
  }
  
  
  providers = { 
    aws = aws.us_east_1
    panos = panos
  }
  
  # Security group settings
  security_group_name = each.value.sg_name
  security_group_description = each.value.sg_description
  vpc_id = each.value.policy.security_group.vpc_id
  tags = each.value.tags
  
  # Rule settings
  protocol = each.value.rule.protocol
  from_port = each.value.rule.port
  to_port = each.value.rule.port
  source_cidr = each.value.cidr
  description = "Allow access from ${each.value.rule.source.account_id} (${each.value.rule.request_id})"
  rule_tags = each.value.rule_tags
  
  # Palo Alto settings
  enable_palo_inspection = false
  name_prefix = each.value.policy.security_group.thirdpartyName
  request_id = each.value.rule.request_id
  appid = each.value.rule.appid
  url = each.value.rule.url
  source_info = each.value.rule.source
}

# Create provider security groups for use1 regions
module "provider_us_east_1" {
  source = "./modules/provider"
  
  for_each = {
    for rule in local.consumer_rules :
    rule.key => rule
    if rule.region == "us-east-1"
  }
  
  
  providers = { 
    aws = aws.us_east_1
    panos = panos
  }
  
  # Security group settings
  security_group_name = each.value.sg_name
  security_group_description = each.value.sg_description
  vpc_id = each.value.policy.security_group.vpc_id
  tags = each.value.tags
  
  # Rule settings
  protocol = each.value.rule.protocol
  from_port = each.value.rule.port
  to_port = each.value.rule.port
  destination_cidr = each.value.cidr
  description = "Allow access to backend (${each.value.rule.request_id})"
  rule_tags = each.value.rule_tags
  
  # Palo Alto settings
  enable_palo_inspection = false
  name_prefix = each.value.policy.security_group.internalAppID
  request_id = each.value.rule.request_id
  appid = each.value.rule.appid
  url = each.value.rule.url
}

# Create consumer security groups for use1 regions
module "consumer_us_west_2" {
  source = "./modules/consumer"
  
  for_each = {
    for rule in local.provider_rules :
    rule.key => rule
    if rule.region == "us-west-2"
  }
  
  providers = { 
    aws = aws.us_west_2
    panos = panos
  }
  
  # Security group settings
  security_group_name = each.value.sg_name
  security_group_description = each.value.sg_description
  vpc_id = each.value.policy.security_group.vpc_id
  tags = each.value.tags
  
  # Rule settings
  protocol = each.value.rule.protocol
  from_port = each.value.rule.port
  to_port = each.value.rule.port
  source_cidr = each.value.cidr
  description = "Allow access from ${each.value.rule.source.account_id} (${each.value.rule.request_id})"
  rule_tags = each.value.rule_tags
  
  # Palo Alto settings
  enable_palo_inspection = false
  name_prefix = each.value.policy.security_group.thirdpartyName
  request_id = each.value.rule.request_id
  appid = each.value.rule.appid
  url = each.value.rule.url
  source_info = each.value.rule.source
}

# Create provider security groups for use1 regions
module "provider_us_west_2" {
  source = "./modules/provider"
  
  for_each = {
    for rule in local.provider_rules :
    rule.key => rule
    if rule.region == "us-west-2"
  }
  
  
  providers = { 
    aws = aws.us_west_2
    panos = panos
  }
  
  # Security group settings
  security_group_name = each.value.sg_name
  security_group_description = each.value.sg_description
  vpc_id = each.value.policy.security_group.vpc_id
  tags = each.value.tags
  
  # Rule settings
  protocol = each.value.rule.protocol
  from_port = each.value.rule.port
  to_port = each.value.rule.port
  destination_cidr = each.value.cidr
  description = "Allow access to backend (${each.value.rule.request_id})"
  rule_tags = each.value.rule_tags
  
  # Palo Alto settings
  enable_palo_inspection = false
  name_prefix = each.value.policy.security_group.internalAppID
  request_id = each.value.rule.request_id
  appid = each.value.rule.appid
  url = each.value.rule.url
}