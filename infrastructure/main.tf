module "us_west_2" {
  providers     = aws.us-west-2
  source        = "./module"
  region        = "us-west-2"
  policies = "${path.module}/policies/us-west-2"
  
}

module "us_east_1" {
  providers     = aws.us-east-1
  source        = "./module"
  region        = "us-east-1"
  policies = "${path.module}/policies/us-east-1"

}
