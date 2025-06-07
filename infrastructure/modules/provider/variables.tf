variable "security_group_name" {
  description = "Name of the security group"
  type        = string
}

variable "security_group_description" {
  description = "Description of the security group"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the security group will be created"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the security group"
  type        = map(string)
  default     = {}
}

variable "rule_tags" {
  description = "Tags to apply to the security group rules"
  type        = map(string)
  default     = {}
}

variable "protocol" {
  description = "Protocol for the security group rule"
  type        = string
  default     = "tcp"
}

variable "from_port" {
  description = "Start port for the security group rule"
  type        = number
  default     = 0
}

variable "to_port" {
  description = "End port for the security group rule"
  type        = number
  default     = 0
}

variable "source_cidrs" {
  description = "Source CIDR block"
  type        = list(string)
  default     = [""]
}

variable "destination_cidrs" {
  description = "List of destination CIDR blocks"
  type        = list(string)
  default     = []
}


variable "description" {
  description = "Description for the security group rule"
  type        = string
  default     = ""
}

# Palo Alto specific variables
variable "enable_palo_inspection" {
  description = "Whether to enable Palo Alto inspection"
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Prefix for Palo Alto rule names"
  type        = string
  default     = "rule"
}

variable "request_id" {
  description = "Request ID for tracking"
  type        = string
  default     = ""
}

variable "appid" {
  description = "Application ID for Palo Alto rule"
  type        = string
  default     = "any"
}

variable "url" {
  description = "URL for the service"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region for the Panorama device group"
  type        = string
}


variable "aws_rules" {
  description = "Pre-processed AWS security group rules"
  type = map(object({
    protocol = string
    port = number
    cidr = string
    description = string
    rule_tags = map(string)
  }))
}

# Palo Alto variables
variable "enable_palo_inspection" {
  description = "Enable Palo Alto inspection"
  type        = bool
  default     = false
}

variable "palo_protocols_ports" {
  description = "List of protocol-port combinations for Palo Alto (e.g., ['tcp-443', 'tcp-69'])"
  type        = list(string)
  default     = []
}

variable "palo_destination_ips" {
  description = "List of all destination IPs for Palo Alto"
  type        = list(string)
  default     = []
}