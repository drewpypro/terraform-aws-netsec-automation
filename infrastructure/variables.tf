# variable "palo_host" {
#   description = "Elastic IP or DNS of the Palo instance"
#   type        = string
# }

variable "palo_username" {
  description = "Palo admin username"
  type        = string
  sensitive   = true
}

variable "palo_password" {
  description = "Palo admin password"
  type        = string
  sensitive   = true
}