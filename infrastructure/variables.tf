variable "palo_hostname" {
  description = "Hostname of the Palo Alto firewall or Panorama"
  type        = string
}

variable "palo_username" {
  description = "Username for the Palo Alto firewall or Panorama"
  type        = string
}

variable "palo_password" {
  description = "Password for the Palo Alto firewall or Panorama"
  type        = string
}

variable "HOME_IP" {
  description = "Public IP for sourcing management connections"
  type        = string
}
