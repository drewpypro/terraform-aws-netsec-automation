resource "panos_panorama_service_object" "service" {
  for_each        = toset(var.service_objects)
  name            = each.value
  device_group    = "${var.region}-fw-dg"
  protocol        = split("-", each.value)[0]
  destination_port= split("-", each.value)[1]
}

resource "panos_panorama_administrative_tag" "tag" {
  for_each     = toset(var.tags)
  name         = each.value
  device_group = "${var.region}-fw-dg"
  color        = "color6"
}

resource "panos_custom_url_category" "url_category" {
  for_each     = toset(var.url_categories)
  name         = substr(each.value, 0, 63) # Truncate for PAN-OS limit
  device_group = "${var.region}-fw-dg"
  sites        = [each.value]
  type         = "URL List"
}

# Outputs for consumer modules to reference by name
output "service_names" {
  value = [for s in panos_panorama_service_object.service : s.name]
}
output "tag_names" {
  value = [for t in panos_panorama_administrative_tag.tag : t.name]
}
output "url_category_names" {
  value = [for u in panos_custom_url_category.url_category : u.name]
}
