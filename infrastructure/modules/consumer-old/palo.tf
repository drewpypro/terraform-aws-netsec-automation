
# resource "panos_panorama_service_object" "consumer_services" {
#   count            = length(var.palo_rules)
#   name             = "svc-${count.index}"
#   device_group     = "${var.region}-fw-dg"
#   protocol         = var.palo_rules[count.index].protocol
#   destination_port = var.palo_rules[count.index].port
# }

# resource "panos_panorama_administrative_tag" "consumer_tag" {
#   count        = length(var.palo_rules)
#   name         = "tag-${count.index}"
#   device_group = "${var.region}-fw-dg"
#   color        = "color6"
#   comment      = "Auto-tag for rule ${count.index}"
# }

# resource "panos_custom_url_category" "consumer_category" {
#   count        = length(var.palo_rules)
#   name         = substr(replace(replace(var.palo_rules[count.index].url, "https://", ""), "/", "-"), 0, 63)
#   device_group = "${var.region}-fw-dg"
#   sites        = [var.palo_rules[count.index].url]
# }

# resource "panos_panorama_security_rule_group" "consumer_group" {
#   count        = length(var.palo_rules)
#   rulebase     = "pre-rulebase"
#   device_group = "${var.region}-fw-dg"
#   name         = "grp-${count.index}"

#   rules {
#     name                  = "rule-${count.index}"
#     application           = [var.palo_rules[count.index].appid]
#     source_zones          = ["trust"]
#     destination_zones     = ["untrust"]
#     source_addresses      = var.palo_rules[count.index].source_ips
#     destination_addresses = ["any"]
#     service               = [panos_panorama_service_object.consumer_services[count.index].name]
#     action                = "allow"
#     category              = [panos_custom_url_category.consumer_category[count.index].name]
#     tags                  = [panos_panorama_administrative_tag.consumer_tag[count.index].name]
#   }
# }
