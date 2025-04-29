resource "aws_vpc_endpoint" "ec2_service_vpce" {
  vpc_id            = aws_vpc.test_vpc.id
  service_name      = "com.amazonaws.us-west-2.ec2"
  vpc_endpoint_type = "Interface"

  subnet_configuration {
    ipv4      = "192.168.2.31"
    subnet_id = aws_subnet.vpce_subnet.id
  }

  subnet_ids = [aws_subnet.vpce_subnet.id]

  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

}

resource "aws_vpc_endpoint" "thirdparty_vpce" {
  vpc_id            = aws_vpc.test_vpc.id
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_endpoint_type = "Interface"

  subnet_configuration {
    ipv4      = "10.69.0.32"
    subnet_id = aws_subnet.thirdparty_subnet.id
  }

  subnet_ids = [aws_subnet.thirdparty_subnet.id]

  security_group_ids = [aws_security_group.thirdparty_vpce_sg.id]
}
