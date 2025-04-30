variable "region" {
  type        = string
  description = "The AWS region for this workspace (e.g. us-west-2)"
  default     = "us-west-2"
}

variable "palo_host" {
  description = "Elastic IP or DNS of the Palo instance"
  type        = string
  default     = "54.214.37.204/32"
}

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