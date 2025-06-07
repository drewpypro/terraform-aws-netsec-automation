resource "panos_panorama_service_object" "provider_services" {
  for_each = var.enable_palo_inspection ? toset(var.palo_protocols_ports) : []
  
  device_group = "${var.region}-fw-dg"
  name         = each.value  # e.g., "tcp-443", "tcp-69"
  protocol     = split("-", each.value)[0]  # "tcp"
  destination_port = split("-", each.value)[1]  # "443" or "69"
}

# Create URL category for the application
resource "panos_custom_url_category" "provider_category" {
  count = var.enable_palo_inspection ? 1 : 0
  
  device_group = "${var.region}-fw-dg"
  name         = "${var.name_prefix}-${var.request_id}-urls"
  sites         = [replace(var.url, "https://", "")]  # Remove https:// prefix
  type         = "URL List"
}

# Create Panorama rule for consumer (ingress) traffic
resource "panos_panorama_security_rule_group" "provider_rule" {
  count = var.enable_palo_inspection ? 1 : 0
  
  # Depend on the service and category objects being created first
  depends_on = [
    panos_panorama_service_object.provider_services,
    panos_custom_url_category.provider_category
  ]
  
  device_group = "${var.region}-fw-dg"
  position_keyword = "bottom"
  
  rule {
    name                  = "pl-provider-${var.name_prefix}-${var.request_id}"
    source_zones          = ["any"]
    source_addresses      = ["100.64.0.0/23"]
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = var.palo_destination_ips
    applications          = [var.appid]
    services              = [for service in panos_panorama_service_object.provider_services : service.name]  # Use created services
    categories            = var.enable_palo_inspection ? [panos_custom_url_category.provider_category[0].name] : []  # Use created category
    action                = "allow"
    description           = "Allow PrivateLink provider traffic (${var.name_prefix})"
    
    tags = [
      "managed-by-terraform",
      "privatelink-provider",
    ]
  }
}