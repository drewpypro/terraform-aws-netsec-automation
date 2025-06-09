# Create service objects for each unique protocol/port combination
resource "panos_panorama_service_object" "consumer_services" {
  for_each = var.enable_palo_inspection ? {
    for rule_key, rule in var.palo_rules : "${rule.protocol}-${rule.port}" => {
      protocol = rule.protocol
      port = rule.port
    }
  } : {}
  
  device_group = "${var.region}-fw-dg"
  name         = each.key  # e.g., "tcp-443", "tcp-9000-10000"
  protocol     = each.value.protocol
  
  # Handle port ranges
  destination_port = each.value.port
}

# Create URL categories for each unique URL
resource "panos_custom_url_category" "consumer_categories" {
  for_each = var.enable_palo_inspection ? {
    for rule_key, rule in var.palo_rules :
    rule_key => rule
    if rule.url != null
  } : {}
  
  device_group = "${var.region}-fw-dg"
  name         = "${var.name_prefix}-${each.key}-urls"
  sites        = [replace(each.value.url, "https://", "")]
  type         = "URL List"
}

# Create individual Palo Alto rules for each unique combination
resource "panos_panorama_security_rule_group" "consumer_rules" {
  for_each = var.enable_palo_inspection ? var.palo_rules : {}
  
  depends_on = [
    panos_panorama_service_object.consumer_services,
    panos_custom_url_category.consumer_categories
  ]
  
  device_group = "${var.region}-fw-dg"
  position_keyword = "bottom"
  
  rule {
    name = "pl-consumer-${var.name_prefix}-${regex("(vpce-svc-[a-zA-Z0-9]+)", var.service_name)[0]}-${var.region}-${each.key}"
    source_zones          = ["any"]
    source_addresses      = each.value.source_ips
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["100.64.0.0/23"]
    applications          = [each.value.appid]
    services              = ["${each.value.protocol}-${each.value.port}"]
    categories            = each.value.url != null ? ["${var.name_prefix}-${each.key}-urls"] : []
    action                = "allow"
    description           = "Allow PrivateLink consumer traffic (${each.value.request_id})"
    
    tags = [
      "managed-by-terraform",
      "privatelink-consumer",
      each.value.request_id
    ]
  }
}