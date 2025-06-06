# # Create Panorama rule for consumer (ingress) traffic in the appropriate device group
# resource "panos_panorama_security_rule_group" "rule" {
#   count = var.enable_palo_inspection ? 1 : 0
  
#   device_group = "${var.region}-fw-dg"  # Regional device group
#   position_keyword = "bottom"
  
#   rule {
#     name                  = var.palo_rule_name
#     source_zones          = ["any"]
#     source_addresses      = var.palo_source_cidrs
#     source_users          = ["any"]
#     destination_zones     = ["any"]
#     destination_addresses = ["100.64.0.0/23"]  # Updated to /23 as per your requirements
#     applications          = var.palo_appids
#     services              = ["application-default"]
#     categories            = ["any"]
#     action                = "allow"
#     description           = var.palo_description
    
#     tags = [
#       "managed-by-terraform",
#       "privatelink-consumer",
#     ]
#   }
# }