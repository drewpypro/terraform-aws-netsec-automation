# modules/network_stack/variables.tf

variable "region" {
  description = "AWS region for this instance of the module"
  type        = string
}

variable "policies_path" {
  description = "Relative path to the folder containing region-specific sgs.yaml and rules.yaml"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the regional VPC"
  type        = string
}
