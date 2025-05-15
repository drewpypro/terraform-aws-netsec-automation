# # Create Panorama rule for consumer (ingress) traffic in the appropriate device group
# resource "panos_panorama_security_rule_group" "rule" {
#   count = var.enable_palo_inspection ? 1 : 0
  
#   device_group = "${var.region}-fw-dg"  # Regional device group
#   position_keyword = "bottom"
  
#   rule {
#     name                  = "pl-consumer-${var.name_prefix}-${var.request_id}"
#     source_zones          = ["any"]
#     source_addresses      = var.source_cidrs
#     source_users          = ["any"]
#     destination_zones     = ["any"]
#     destination_addresses = ["100.64.0.0/24"]  # Privatelink Endpoint Subnet
#     applications          = [var.appid]
#     services              = ["application-default"]
#     categories            = ["any"]
#     action                = "allow"
#     description           = "${var.description} (${var.request_id})"
    
#     tags = [
#       "managed-by-terraform",
#       "privatelink-consumer",
#     ]
#   }
# }