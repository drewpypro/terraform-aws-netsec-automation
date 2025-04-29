resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Empty SG for EC2"
  vpc_id      = aws_vpc.test_vpc.id
}

resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpce-sg"
  description = "Empty SG for VPC endpoint"
  vpc_id      = aws_vpc.test_vpc.id
}

resource "aws_security_group" "thirdparty_vpce_sg" {
  name        = "thirdparty-vpce-sg"
  description = "Empty SG for Thirdparty PrivateLink endpoint"
  vpc_id      = aws_vpc.test_vpc.id
}

resource "aws_security_group" "paloalto_vm_sg" {
  name        = "paloalto-vm-sg"
  description = "Palo Alto VM"
  vpc_id      = aws_vpc.test_vpc.id
}
