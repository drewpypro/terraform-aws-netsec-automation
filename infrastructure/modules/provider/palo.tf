# Create Panorama rule for provider (egress) traffic in the appropriate device group
resource "panos_panorama_security_rule_group" "rule" {
  count = var.enable_palo_inspection ? 1 : 0
  
  device_group = "${var.region}-fw-dg"  # Regional device group
  position_keyword = "bottom"
  
  rule {
    name                  = "pl-provider-${var.name_prefix}-${var.request_id}"
    source_zones          = ["any"]
    source_addresses      = ["100.65.0.0/24"]  # Frontend Subnet
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = var.destination_cidrs
    applications          = [var.appid]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "allow"
    description           = "${var.description} (${var.request_id})"
    
    tags = [
      "managed-by-terraform",
      "privatelink-provider",
    ]
  }
}