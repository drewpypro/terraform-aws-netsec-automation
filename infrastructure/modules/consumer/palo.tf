resource "panos_panorama_service_object" "consumer_services" {
  for_each = var.enable_palo_inspection ? toset(var.palo_protocols_ports) : []

  device_group     = "${var.region}-fw-dg"
  name             = each.value
  protocol         = split("-", each.value)[0]
  destination_port = split("-", each.value)[1]
}

resource "panos_custom_url_category" "consumer_category" {
  count = var.enable_palo_inspection ? 1 : 0

  device_group = "${var.region}-fw-dg"
  name         = "${var.name_prefix}-${var.region}-urls"
  sites        = [replace(var.url, "https://", "")]
  type         = "URL List"
}

resource "panos_panorama_security_rule_group" "consumer_rule" {
  count = var.enable_palo_inspection ? 1 : 0

  depends_on = [
    panos_panorama_service_object.consumer_services,
    panos_custom_url_category.consumer_category
  ]

  device_group     = "${var.region}-fw-dg"
  position_keyword = "bottom"

  rule {
    name                   = "pl-consumer-${var.name_prefix}-${regex("(vpce-svc-[a-zA-Z0-9]+)", var.service_name)[0]}-${var.region}"
    source_zones           = ["any"]
    source_addresses       = var.palo_source_ips
    source_users           = ["any"]
    destination_zones      = ["any"]
    destination_addresses  = ["100.64.0.0/23"]
    applications           = [var.appid]
    services               = [for s in values(panos_panorama_service_object.consumer_services) : s.name]
    categories             = var.enable_palo_inspection ? [panos_custom_url_category.consumer_category[0].name] : []
    action                 = "allow"
    description            = "Allow PrivateLink consumer traffic (${var.name_prefix}-${regex("(vpce-svc-[a-zA-Z0-9]+)", var.service_name)[0]}-${var.region})"

    tags = [
      "managed-by-terraform",
      "privatelink-consumer",
    ]
  }
}
