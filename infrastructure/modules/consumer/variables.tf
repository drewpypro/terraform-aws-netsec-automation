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

variable "sg_rules" {
  description = "Map of security group rules grouped by protocol-port"
  type = map(object({
    protocol                = string
    port                   = number
    appid                  = string
    url                    = string
    enable_palo_inspection = bool
    request_ids            = list(string)
    source_cidrs           = list(string)
    source_account_id      = string
    source_vpc_id          = string
    source_region          = string
    rule_tags              = map(string)
  }))
}

# Palo Alto variables
variable "enable_palo_inspection" {
  description = "Enable Palo Alto inspection for this security group"
  type        = bool
  default     = false
}

variable "palo_rule_name" {
  description = "Name for the Palo Alto rule"
  type        = string
  default     = ""
}

variable "palo_source_cidrs" {
  description = "All source CIDRs for Palo Alto rule"
  type        = list(string)
  default     = []
}

variable "palo_appids" {
  description = "All application IDs for Palo Alto rule"
  type        = list(string)
  default     = []
}

variable "palo_urls" {
  description = "All URLs for Palo Alto rule"
  type        = list(string)
  default     = []
}

variable "palo_description" {
  description = "Description for Palo Alto rule"
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "request_ids" {
  description = "All request IDs"
  type        = list(string)
  default     = []
}