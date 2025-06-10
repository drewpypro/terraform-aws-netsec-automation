resource "panos_panorama_service_object" "consumer_services" {
  for_each = var.enable_palo_inspection ? toset(var.palo_protocols_ports) : []

  device_group     = "${var.region}-fw-dg"
  name             = each.value
  protocol         = split("-", each.value)[0]
  destination_port = split("-", each.value)[1]
}

resource "panos_custom_url_category" "consumer_category" {
  for_each = {
    for key, rule in var.palo_rules :
    replace(rule.url, "https://", "") => rule
    if var.enable_palo_inspection && rule.url != "any"
  }

  device_group = "${var.region}-fw-dg"
  name         = each.key                               
  sites        = [each.value.url]                       
  type         = "URL List"
}

resource "panos_panorama_security_rule_group" "consumer_rules" {
  for_each = var.enable_palo_inspection ? var.palo_rules : {}

  depends_on = [
    panos_panorama_service_object.consumer_services,
    panos_custom_url_category.consumer_category
  ]

  device_group     = "${var.region}-fw-dg"
  position_keyword = "bottom"

  rule {
    name = "pl-${var.name_prefix}-${regex("(vpce-svc-[a-zA-Z0-9]+)", var.service_name)[0]}-${var.region}-r${index(keys(var.palo_rules), each.key)}"
    source_zones           = ["any"]
    source_addresses       = each.value.source_ips
    source_users           = ["any"]
    destination_zones      = ["any"]
    destination_addresses  = ["100.64.0.0/23"]
    applications           = [each.value.appid]
    services               = [
      panos_panorama_service_object.consumer_services["${each.value.protocol}-${each.value.port}"].name
    ]
    categories = (
      each.value.url != "any"
      ? [replace(each.value.url, "https://", "")]
      : ["any"]
    )
    action      = "allow"
    description = "Allow ${var.name_prefix} ${each.value.protocol}/${each.value.port} ${each.value.appid} ${each.value.url}"

    tags = [
      "managed-by-terraform",
      "privatelink-consumer",
    ]
  }
} 
