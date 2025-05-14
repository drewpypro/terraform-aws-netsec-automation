# Create Palo Alto rule for consumer (ingress) traffic if enabled
resource "panos_security_policy" "rule" {
  count = var.enable_palo_inspection ? 1 : 0
  
  rule {
    name                  = "pl-consumer-${var.name_prefix}-${var.request_id}"
    source_zones          = ["any"]
    source_addresses      = var.source_cidrs
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["SG-${var.security_group_name}"]  # Using a naming convention for SG
    applications          = [var.appid]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "allow"
    description           = "${var.description} (${var.request_id})"
    
    tags = [
      "managed-by-terraform",
      "privatelink-consumer",
      "request-${var.request_id}"
    ]
  }
}