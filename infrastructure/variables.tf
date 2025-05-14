variable "panos_hostname" {
  description = "Hostname of the Palo Alto firewall or Panorama"
  type        = string
}

variable "panos_username" {
  description = "Username for the Palo Alto firewall or Panorama"
  type        = string
}

variable "panos_password" {
  description = "Password for the Palo Alto firewall or Panorama"
  type        = string
  sensitive   = true
}