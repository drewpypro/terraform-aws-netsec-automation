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
  description = "AWS service name for the PrivateLink endpoint"
  type        = string
}

variable "aws_rules" {
  description = "Pre-processed AWS security group rules"
  type = map(object({
    protocol    = string
    from_port   = number
    to_port     = number
    cidr        = string
    description = string
    rule_tags   = map(string)
  }))
}

variable "name_prefix" {
  description = "Prefix for Palo Alto rule names"
  type        = string
}

variable "request_id" {
  description = "Request ID for tracking"
  type        = string
}

variable "palo_rules" {
  description = "Pre-processed Palo Alto rules grouped by protocol/port/appid/url"
  type = map(object({
    protocol               = string
    from_port             = number
    to_port               = number
    port_key              = string
    appid                 = string
    url                   = string
    source_ips            = list(string)
    enable_palo_inspection = bool
  }))
  default = {}
}