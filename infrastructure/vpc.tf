provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "test_vpc" {
  cidr_block = "192.168.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true
}


resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "ec2_subnet" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "us-west-2a"
}

resource "aws_subnet" "vpce_subnet" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "192.168.2.0/24"
  availability_zone       = "us-west-2a"
}

resource "aws_subnet" "firewall_subnet" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "192.168.3.0/24"
  availability_zone       = "us-west-2a"
}

resource "aws_subnet" "thirdparty_subnet" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-west-2a"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "Test-IGW"
  }
}

resource "aws_route_table" "general_rt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    cidr_block = "10.0.0.0/24"
    network_interface_id = aws_network_interface.palo_dataplane.id
  }

  tags = {
    Name = "general-rt"
  }
}

resource "aws_route_table_association" "ec2_rt_assoc" {
  subnet_id      = aws_subnet.ec2_subnet.id
  route_table_id = aws_route_table.general_rt.id
}

resource "aws_route_table_association" "vpce_rt_assoc" {
  subnet_id      = aws_subnet.vpce_subnet.id
  route_table_id = aws_route_table.general_rt.id
}

# Firewall RT (locals only)
resource "aws_route_table" "firewall_rt" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "firewall-rt"
  }
}

resource "aws_route_table_association" "firewall_rt_assoc" {
  subnet_id      = aws_subnet.firewall_subnet.id
  route_table_id = aws_route_table.firewall_rt.id
}

# Thirdparty RT
resource "aws_route_table" "thirdparty_rt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "192.168.0.0/22"
    network_interface_id = aws_network_interface.palo_dataplane.id
  }

  tags = {
    Name = "thirdparty-rt"
  }
}

resource "aws_route_table_association" "thirdparty_rt_assoc" {
  subnet_id      = aws_subnet.thirdparty_subnet.id
  route_table_id = aws_route_table.thirdparty_rt.id
}
