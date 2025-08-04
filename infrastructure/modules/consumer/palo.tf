
# resource "panos_panorama_service_object" "consumer_services" {
#   count            = length(var.palo_rules)
#   name             = "svc-${count.index}"
#   device_group     = "${var.region}-fw-dg"
#   protocol         = var.palo_rules[count.index].protocol
#   destination_port = var.palo_rules[count.index].port
# }

# # resource "panos_panorama_administrative_tag" "consumer_tag" {
# #   count        = length(var.palo_rules)
# #   name         = "tag-${count.index}"
# #   device_group = "${var.region}-fw-dg"
# #   color        = "color6"
# #   comment      = "Auto-tag for rule ${count.index}"
# # }


# resource "panos_custom_url_category" "consumer_category" {
#   count        = length(var.palo_rules)
#   name         = substr(replace(replace(var.palo_rules[count.index].url, "https://", ""), "/", "-"), 0, 63)
#   device_group = "${var.region}-fw-dg"
#   sites        = [replace(var.palo_rules[count.index].url, "https://", "")]
#   type         = "URL List"
# }


# resource "panos_panorama_security_rule_group" "consumer_group" {
#   for_each     = { for idx, rule in var.palo_rules : idx => rule }
#   rulebase     = "pre-rulebase"
#   device_group = "${var.region}-fw-dg"

#   rule {
#     name                  = "rule-${each.key}"
#     applications           = [each.value.appid]
#     source_zones          = ["trust"]
#     destination_zones     = ["untrust"]
#     source_addresses      = each.value.source_ips
#     destination_addresses = ["any"]
#     services               = [panos_panorama_service_object.consumer_services[each.key].name]
#     action                = "allow"
#     categories              = [panos_custom_url_category.consumer_category[each.key].name]
#     source_users           = ["any"]
#     tags = [
#       "managed-by-terraform",
#       "privatelink-consumer",
#     ]
#   }
# }
