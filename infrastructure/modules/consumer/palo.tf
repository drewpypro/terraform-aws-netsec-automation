# Create service objects for each unique protocol/port combination
resource "panos_panorama_service_object" "consumer_services" {
  for_each = {
    for rule_key, rule in var.palo_rules : 
    "${rule.protocol}-${rule.port_key}" => rule
    if rule.enable_palo_inspection
  }
  
  device_group = "${var.region}-fw-dg"
  name         = "${each.value.protocol}-${each.value.port_key}"
  protocol     = each.value.protocol
  destination_port = each.value.from_port != each.value.to_port ? "${each.value.from_port}-${each.value.to_port}" : tostring(each.value.from_port)
}

# Create URL categories for each unique URL
resource "panos_custom_url_category" "consumer_categories" {
  for_each = toset([
    for rule_key, rule in var.palo_rules : 
    rule.url
    if rule.enable_palo_inspection && rule.url != "any"
  ])
  
  device_group = "${var.region}-fw-dg"
  name         = "${substr(var.name_prefix, 0, 8)}-${substr(var.region, -1, 1)}-${substr(replace(replace(each.key, ".", ""), "-", ""), 0, 15)}-url"
  sites        = [each.key]
  type         = "URL List"
}

# Create Panorama rules - one for each unique protocol/port/appid/url combination
resource "panos_panorama_security_rule_group" "consumer_rules" {
  for_each = {
    for rule_key, rule in var.palo_rules : 
    rule_key => rule
    if rule.enable_palo_inspection
  }
  
  # Depend on the service and category objects being created first
  depends_on = [
    panos_panorama_service_object.consumer_services,
    panos_custom_url_category.consumer_categories
  ]
  
  device_group = "${var.region}-fw-dg"
  position_keyword = "bottom"
  
  rule {
    name = "pl-${substr(var.name_prefix, 0, 6)}-${substr(var.region, -1, 1)}-${each.value.protocol}-${each.value.port_key}-${substr(each.value.appid, 0, 4)}-${substr(replace(each.value.url, ".", ""), 0, 10)}"
    source_zones          = ["any"]
    source_addresses      = each.value.source_ips
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["100.64.0.0/23"]
    applications          = [each.value.appid]
    services              = [panos_panorama_service_object.consumer_services["${each.value.protocol}-${each.value.port_key}"].name]
    categories            = each.value.url != "any" ? [panos_custom_url_category.consumer_categories[each.value.url].name] : []
    action                = "allow"
    description           = "Allow PrivateLink consumer traffic (${var.name_prefix}-${regex("(vpce-svc-[a-zA-Z0-9]+)", var.service_name)[0]}-${var.region}) - ${each.value.protocol}/${each.value.port_key}/${each.value.appid}/${each.value.url}"
    
    tags = [
      "managed-by-terraform",
      "privatelink-consumer",
    ]
  }
}