resource "panos_panorama_service_object" "consumer_services" {
  for_each = var.enable_palo_inspection ? toset(var.palo_protocols_ports) : []

  device_group     = "${var.region}-fw-dg"
  name             = each.value
  protocol         = split("-", each.value)[0]
  destination_port = can(regex("-", var.palo_rules[count.index].port)) ? "${split("-", var.palo_rules[count.index].port)[0]}-${split("-", var.palo_rules[count.index].port)[1]}" : var.palo_rules[count.index].port
}

resource "panos_custom_url_category" "consumer_category" {
  for_each = {
    for url_key in distinct([
      for rule in var.palo_rules : replace(rule.url, "https://", "")
      if var.enable_palo_inspection && rule.url != "any"
    ]) : url_key => {
      sites = ["https://${url_key}"]
    }
  }

  device_group = "${var.region}-fw-dg"
  name         = substr(each.key, 0, 31)
  sites        = each.value.sites
  type         = "URL List"
}

resource "panos_panorama_security_rule_group" "consumer_rules" {
  for_each = var.enable_palo_inspection ? var.palo_rules : {}

  depends_on = [
    panos_panorama_service_object.consumer_services,
    panos_custom_url_category.consumer_category
  ]

  device_group     = "${var.region}-fw-dg"

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
      ? [substr(replace(each.value.url, "https://", ""), 0, 31)]
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