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

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# provider "panos" {
#   alias    = "us-west-2"
#   hostname = "firewall-west.drewpy.pro"
#   username = var.palo_username
#   password = var.palo_password
# }

# provider "panos" {
#   alias    = "us-east-1"
#   hostname = "firewall-east.drewpy.pro"
#   username = var.palo_username
#   password = var.palo_password
# }

# provider "panos" {
#   hostname = "54.214.37.204"
#   username = var.palo_username
#   password = var.palo_password
# }

# data "panos_system_info" "ngfw_info" { }

# output "the_info" {
#     value = data.panos_system_info.ngfw_info
# }

# resource "null_resource" "commit_palo_ssh" {
#   provisioner "local-exec" {
#     command = "sshpass -p '${var.palo_password}' ssh -o StrictHostKeyChecking=no ${var.palo_username}@54.214.37.204 'configure; commit'"
#   }

#   triggers = {
#     always_run = timestamp()
#   }

#   depends_on = [panos_security_policy.from_yaml]
# }