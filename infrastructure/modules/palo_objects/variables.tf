variable "service_objects" {
  description = "Unique deduped list of protocol-port service objects for Palo Alto (e.g. [\"tcp-443-445\"])"
  type        = list(string)
}

variable "tags" {
  description = "Unique deduped list of tag names for Palo Alto"
  type        = list(string)
}

variable "url_categories" {
  description = "Unique deduped list of URL category names for Palo Alto"
  type        = list(string)
}

variable "region" {
  description = "Region, used to determine device group (e.g. us-east-1)"
  type        = string
}
