module "vpc_us_west_2" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  providers = {
    aws = aws.us_west_2
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
    aws = aws.us_east_1
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

resource "aws_security_group" "panorama" {
  provider    = aws.us_east_1
  name        = "allow_panorama_access"
  description = "Allow inbound traffic for testing automation"
  vpc_id      = module.vpc_us_east_1.vpc_id

  tags = {
    Name = "panorama_vm_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_panorama_ingress_443" {
  provider          = aws.us_east_1
  security_group_id = aws_security_group.panorama.id
  cidr_ipv4         = var.HOME_IP
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_panorama_ingress_22" {
  provider          = aws.us_east_1
  security_group_id = aws_security_group.panorama.id
  cidr_ipv4         = var.HOME_IP
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_panorama_ingress_icmp" {
  provider          = aws.us_east_1
  security_group_id = aws_security_group.panorama.id
  cidr_ipv4         = var.HOME_IP
  ip_protocol       = "icmp"
  from_port         = "-1"
  to_port           = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_panorama_egress_all" {
  provider          = aws.us_east_1
  security_group_id = aws_security_group.panorama.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "panorama_vm_2" {
  provider        = aws.us_east_1

  ami             = "ami-0d016c7e722bdf4a5"
  instance_type   = "c4.4xlarge"
  subnet_id       = module.vpc_us_east_1.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.panorama.id]
  associate_public_ip_address = "true"
  key_name = "panorama_key"

  tags = {
    Name = "panorama_vm_2"
  }

}
