resource "panos_panorama_administrative_tag" "tag_objs" {
  for_each = { for tag in var.tags : tag => tag }

  device_group = "AWS"
  name         = each.value
  color        = "color6"
  comment      = "Auto-tag for rule ${each.key}"
}
