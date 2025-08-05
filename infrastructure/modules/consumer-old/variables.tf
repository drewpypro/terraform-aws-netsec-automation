variable "region" {
  description = "AWS region"
  type        = string
}

variable "security_group_name" {
  description = "Name of the security group"
  type        = string
}

variable "security_group_description" {
  description = "Description of the security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the security group"
  type        = map(string)
  default     = {}
}

variable "aws_rules" {
  description = "Pre-processed AWS security group rules"
  type = map(object({
    protocol    = string
    port        = string
    from_port   = number
    to_port     = number
    cidr        = string
    description = string
    rule_tags   = map(string)
  }))
}

# Palo Alto variables
variable "enable_palo_inspection" {
  description = "Enable Palo Alto inspection"
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Name prefix for Palo Alto rules"
  type        = string
}

variable "request_id" {
  description = "Request ID"
  type        = string
}

variable "appid" {
  description = "Application ID for Palo Alto"
  type        = string
}

variable "url" {
  description = "URL for Palo Alto"
  type        = string
}

variable "palo_protocols_ports" {
  description = "List of protocol-port combinations for Palo Alto (e.g., ['tcp-443', 'tcp-69'])"
  type        = list(string)
  default     = []
}

variable "palo_source_ips" {
  description = "List of all source IPs for Palo Alto"
  type        = list(string)
  default     = []
}

variable "service_name" {
  description = "Full VPC endpoint service name"
  type        = string
}

variable "palo_rules" {
  description = "Pre-processed Palo Alto rules grouped by protocol/port/appid/url"
  type = map(object({
    protocol                = string
    port                    = string
    appid                   = string
    url                     = string
    source_ips              = list(string)
    enable_palo_inspection  = bool
  }))
  default = {}
}

# NEW: Deduped object names passed from palo-objects module
variable "palo_service_objects" {
  description = "List of deduped Palo service object names (e.g., ['tcp-443'])"
  type        = list(string)
  default     = []
}

variable "palo_tags" {
  description = "List of deduped Palo tag names"
  type        = list(string)
  default     = []
}

variable "palo_url_categories" {
  description = "List of deduped Palo url category names"
  type        = list(string)
  default     = []
}
