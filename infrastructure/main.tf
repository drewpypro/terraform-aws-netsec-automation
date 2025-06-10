# Create consumer security groups for us-east-1 region
module "consumer_sg_us_east_1" {
  source = "./modules/consumer"
  
  for_each = try(local.consumer_sgs_by_region["us-east-1"], {})
  
  providers = { 
    aws = aws.us_east_1
    panos = panos
  }
  
  # Security group settings
  region = "us-east-1"
  security_group_name = each.value.sg_name
  security_group_description = each.value.sg_description
  vpc_id = each.value.vpc_id  # Use VPC from policy file
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
}

# Create consumer security groups for us-west-2 region
module "consumer_sg_us_west_2" {
  source = "./modules/consumer"
  
  for_each = try(local.consumer_sgs_by_region["us-west-2"], {})
  
  providers = { 
    aws = aws.us_west_2
    panos = panos
  }
  
  # Security group settings
  region = "us-west-2"
  security_group_name = each.value.sg_name
  security_group_description = each.value.sg_description
  vpc_id = each.value.vpc_id  # Use VPC from policy file
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
}