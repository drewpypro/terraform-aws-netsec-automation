locals {
  east_policy_files = fileset("${path.module}/policies", "*-us-east-1-policy.yaml")
  west_policy_files = fileset("${path.module}/policies", "*-us-west-2-policy.yaml")

  policies_us_east_1 = [
    for f in local.east_policy_files :
    yamldecode(file("${path.module}/policies/${f}"))
  ]

  policies_us_west_2 = [
    for f in local.west_policy_files :
    yamldecode(file("${path.module}/policies/${f}"))
  ]
}