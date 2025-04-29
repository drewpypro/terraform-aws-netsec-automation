resource "aws_instance" "palo_firewall" {
  ami                         = "ami-0ff9efe5244200c6e"
  instance_type               = "m5.2xlarge"
  subnet_id                   = aws_subnet.firewall_subnet.id

  associate_public_ip_address = true

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.palo_dataplane.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.palo_mgmt.id
  }

  tags = {
    Name = "palo-firewall"
  }
}

resource "aws_network_interface" "palo_mgmt" {
  subnet_id       = aws_subnet.ec2_subnet.id
  private_ips     = ["192.168.1.100"]
  security_groups = [aws_security_group.paloalto_vm_sg.id]
}

resource "aws_network_interface" "palo_dataplane" {
  subnet_id       = aws_subnet.firewall_subnet.id
  private_ips     = ["192.168.3.20"]
  security_groups = [aws_security_group.paloalto_vm_sg.id]
}


