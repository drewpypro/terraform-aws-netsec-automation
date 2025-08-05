resource "panos_panorama_security_rule_group" "consumer_rules" {
  for_each = var.enable_palo_inspection ? var.palo_rules : {}

  device_group = "${var.region}-fw-dg"

  rule {
    name = "pl-${var.name_prefix}-${regex("(vpce-svc-[a-zA-Z0-9]+)", var.service_name)[0]}-${var.region}-r${index(keys(var.palo_rules), each.key)}"
    source_zones           = ["any"]
    source_addresses       = each.value.source_ips
    source_users           = ["any"]
    destination_zones      = ["any"]
    destination_addresses  = ["100.64.0.0/23"]
    applications           = [each.value.appid]

    # Reference deduped service object (must match protocol-port pattern)
    services = [
      contains(var.palo_service_objects, "${each.value.protocol}-${each.value.port}")
        ? "${each.value.protocol}-${each.value.port}"
        : "any"
    ]

    # Reference deduped URL category (must match transformed URL)
    categories = (
      each.value.url != "any" && each.value.url != null && each.value.url != "" && contains(var.palo_url_categories, replace(replace(each.value.url, "https://", ""), "/", "-"))
        ? [substr(replace(replace(each.value.url, "https://", ""), "/", "-"), 0, 63)]
        : ["any"]
    )

    action      = "allow"
    description = "Allow ${var.name_prefix} ${each.value.protocol}/${each.value.port} ${each.value.appid} ${each.value.url}"

    tags = var.palo_tags
  }
}
