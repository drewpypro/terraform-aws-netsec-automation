resource "aws_instance" "ec2_app" {
  ami           = "ami-05572e392e80aee89"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.ec2_subnet.id
  private_ip    = "192.168.1.18"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "App-EC2"
  }
}