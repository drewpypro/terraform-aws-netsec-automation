# variable "palo_host" {
#   description = "Elastic IP or DNS of the Palo instance"
#   type        = string
# }

variable "PALO_USERNAME" {
  description = "Palo admin username"
  type        = string
  sensitive   = true
}

variable "PALO_PASSWORD" {
  description = "Palo admin password"
  type        = string
  sensitive   = true
}