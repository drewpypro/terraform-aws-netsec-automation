terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    panos = {
        source  = "paloaltonetworks/panos"
        version = "~> 1.11.0"
    }
    }
  backend "s3" {
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true
    region                      = "us-east-1"
  }
}

provider "panos" {
  hostname = "54.214.37.204"
  username = var.PALO_USERNAME
  password = var.PALO_PASSWORD
}