terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    panos = {
      source  = "paloaltonetworks/panos"
      version = "~> 1.11.0"
    }
  }
}