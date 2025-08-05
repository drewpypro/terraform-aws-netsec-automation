variable "services" {
  description = "List of deduped Palo Alto service objects (tcp-443, tcp-22, etc)"
  type        = list(string)
}

variable "tags" {
  description = "List of deduped Palo Alto tags"
  type        = list(string)
}

variable "urls" {
  description = "List of deduped Palo Alto URL objects"
  type        = list(string)
}
