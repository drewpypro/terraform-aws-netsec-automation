resource "panos_panorama_service_object" "service_objs" {
  for_each         = toset(var.services)

  device_group     = "AWS"
  name             = each.value
  protocol         = split("-", each.value)[0]
  destination_port = split("-", each.value)[1]

}

resource "panos_panorama_administrative_tag" "tag_objs" {
  for_each = { for tag in var.tags : tag => tag }

  device_group = "AWS"
  name         = each.value
  color        = "color6"
  comment      = "Auto-tag for rule ${each.value}"
}

resource "panos_custom_url_category" "url_objs" {
  for_each     = toset(var.urls)

  device_group = "AWS"
  name         = replace(replace(replace(each.value, "https://", ""), ".", "-"), "/", "-")
  description  = each.value
  type         = "URL List"
  sites        = [each.value]
}

output "service_object_names" {
  value = [for s in panos_panorama_service_object.service_objs : s.name]
}

output "tag_object_names" {
  value = [for t in panos_panorama_administrative_tag.tag_objs : t.name]
}

output "url_object_names" {
  value = [for u in panos_custom_url_category.url_objs : u.name]
}
