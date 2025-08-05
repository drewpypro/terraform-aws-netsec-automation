resource "panos_panorama_service_object" "service_objs" {
  for_each         = toset(var.services)

  device_group = "AWS"
  name             = each.value
  protocol         = split("-", each.value)[0]
  destination_port = split("-", each.value)[1]

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

output "url_object_names" {
  value = [for u in panos_custom_url_category.url_objs : u.name]
}
