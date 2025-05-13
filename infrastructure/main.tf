module "us_west_2" {
  source         = "./modules/network_stack"
  region         = "us-west-2"
  policies_path  = "${path.module}/policies/us-west-2"
  providers = {
    aws   = aws.us-west-2
    panos = panos.us-west-2
  }
}

module "us_east_1" {
  source         = "./modules/network_stack"
  region         = "us-east-1"
  policies_path  = "${path.module}/policies/us-east-1"
  providers = {
    aws   = aws.us-east-1
    panos = panos.us-east-1
  }
}
