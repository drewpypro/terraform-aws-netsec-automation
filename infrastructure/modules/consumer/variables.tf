variable "sg_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "aws_rules" {
  type = list(object({
    protocol    = string
    from_port   = number
    to_port     = number
    cidr        = string
    description = string
  }))
}

variable "palo_rules" {
  type = list(object({
    protocol   = string
    port       = string
    appid      = string
    url        = string
    source_ips = list(string)
  }))
}
