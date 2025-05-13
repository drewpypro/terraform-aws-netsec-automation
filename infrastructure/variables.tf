variable "region" {
  type        = string
  description = "The AWS region for this workspace (e.g. us-west-2)"
  default     = "us-west-2"
}

variable "regions" {
  description = "List of AWS regions to deploy VPCs in"
  type        = list(string)
  default     = ["us-west-2", "us-east-1"]
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

variable "vpc_cidr_block" {
  description = "CIDR block to use per region (defaults to /16 per region)"
  type        = map(string)
  default     = {
    us-west-2 = "10.20.0.0/16"
    us-east-1 = "10.30.0.0/16"
  }
}