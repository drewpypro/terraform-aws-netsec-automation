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

variable "service_name" {
  description = "Service name for the VPC endpoint"
  type        = string
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
  default = {}
}

variable "enable_palo_inspection" {
  description = "Whether to enable Palo Alto inspection"
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Prefix for Palo Alto rule names"
  type        = string
}

variable "palo_rules" {
  description = "Pre-processed Palo Alto rules"
  type = map(object({
    protocol               = string
    port                   = string
    appid                  = string
    url                    = optional(string)
    source_ips             = list(string)
    enable_palo_inspection = bool
    request_id             = string
  }))
  default = {}
}