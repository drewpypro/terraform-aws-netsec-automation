resource "panos_panorama_service_object" "consumer_services" {
  for_each = var.enable_palo_inspection ? toset(var.palo_protocols_ports) : []
  
  device_group = "${var.region}-fw-dg"
  name         = each.value  # e.g., "tcp-443", "tcp-69"
  protocol     = split("-", each.value)[0]  # "tcp"
  destination_port = split("-", each.value)[1]  # "443" or "69"
}

# Create URL category for the application
resource "panos_custom_url_category" "consumer_category" {
  count = var.enable_palo_inspection ? 1 : 0
  
  device_group = "${var.region}-fw-dg"
  name         = "${var.name_prefix}-${var.region}-urls"
  sites         = [replace(var.url, "https://", "")]  # Remove https:// prefix
  type         = "URL List"
}

# Create Panorama rule for consumer (ingress) traffic
resource "panos_panorama_security_rule_group" "consumer_rule" {
  count = var.enable_palo_inspection ? 1 : 0
  
  # Depend on the service and category objects being created first
  depends_on = [
    panos_panorama_service_object.consumer_services,
    panos_custom_url_category.consumer_category
  ]
  
  device_group = "${var.region}-fw-dg"
  position_keyword = "bottom"
  
  rule {
    name                  = "pl-consumer-${var.name_prefix}-${var.region}"
    source_zones          = ["any"]
    source_addresses      = ["100.64.0.0/23"]
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = var.palo_destination_ips
    applications          = [var.appid]
    services              = [for service in panos_panorama_service_object.consumer_services : service.name]  # Use created services
    categories            = var.enable_palo_inspection ? [panos_custom_url_category.consumer_category[0].name] : []  # Use created category
    action                = "allow"
    description           = "Allow PrivateLink consumer traffic (${var.name_prefix})"
    
    tags = [
      "managed-by-terraform",
      "privatelink-consumer",
    ]
  }
}