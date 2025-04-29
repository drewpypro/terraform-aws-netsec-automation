resource "aws_instance" "palo_firewall" {
  ami                         = "ami-012b6cc03ca2f0bcc"
  instance_type               = "m5.2xlarge"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.palo_dataplane.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.palo_mgmt.id
  }

  user_data = "op-command-modes=mgmt-interface-swap"

  key_name = "terraform-netsec-automation-testing"

  tags = {
    Name = "palo-firewall"
  }
}

resource "aws_network_interface" "palo_mgmt" {
  subnet_id       = aws_subnet.ec2_subnet.id
  private_ips     = ["192.168.1.100"]
  security_groups = [aws_security_group.paloalto_vm_sg.id]

  tags = {
    Name = "palo-mgmt-eni"
  }
}

resource "aws_network_interface" "palo_dataplane" {
  subnet_id       = aws_subnet.firewall_subnet.id
  private_ips     = ["192.168.3.20"]
  security_groups = [aws_security_group.paloalto_vm_sg.id]

  tags = {
    Name = "palo-dataplane-eni"
  }
}


resource "aws_eip" "palo_mgmt_eip" {
  domain = "vpc"
  
  tags = {
    Name = "palo-mgmt-eip"
  }

}

resource "aws_eip_association" "palo_mgmt_assoc" {
  network_interface_id = aws_network_interface.palo_mgmt.id
  allocation_id        = aws_eip.palo_mgmt_eip.id
}

resource "panos_security_rule_group" "example_ruleset" {
  position_keyword = "bottom"
  rule {
    name                  = "example rule 1"
    source_zones          = ["any"]
    source_addresses      = ["1.1.1.1/32"]
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["2.2.2.2/32"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "panos_security_policy" "from_yaml" {
  for_each = { for rule in local.palo_rules : rule.name => rule }

  rule {
    name                    = each.value.name
    source_zones            = ["any"]
    source_addresses        = [each.value.source_ip]
    source_users            = ["any"]
    destination_zones       = ["any"]
    destination_addresses   = [each.value.destination_ip]
    applications            = [each.value.appid]
    services                = ["application-default"]
    categories              = ["any"]
    action                  = "allow"
    description             = each.value.description
  }
}