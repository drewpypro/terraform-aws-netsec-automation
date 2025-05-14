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

variable "ingress_rules" {
  description = "List of ingress rules to create"
  type = list(object({
    key         = string
    cidr        = string
    description = string
    protocol    = string
    port        = number
    rule_tags   = map(string)
    rule        = any
  }))
  default = []
}