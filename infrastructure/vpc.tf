provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

module "vpc_us_west_2" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  providers = {
    aws = aws.us-west-2
  }

  name = "netsec-vpc-west"
  cidr = "10.10.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  public_subnets  = ["10.10.11.0/24", "10.10.12.0/24"]

  enable_nat_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true
  
  tags = {
    Project = "netsec-automation"
  }
}

module "vpc_us_east_1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  providers = {
    aws = aws.us-east-1
  }

  name = "netsec-vpc-east"
  cidr = "10.20.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.20.1.0/24", "10.20.2.0/24"]
  public_subnets  = ["10.20.11.0/24", "10.20.12.0/24"]

  enable_nat_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true
  map_public_ip_on_launch = true

  tags = {
    Project = "netsec-automation"
  }
}
