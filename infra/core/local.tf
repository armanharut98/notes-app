module "core_infra_parameters" {
  source         = "../modules/ssm-param-reader"
  parameter_list = ["/core/az_count", "/core/vpc_cidr"]
}

module "hub_secrets" {
  source    = "../modules/sm-reader"
  secret_id = "hub/infra-secrets"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  project_name = "core_infra"
  az_suffix    = ["a", "b", "c", "d", "e", "f"]

  core_name_prefix = "${terraform.workspace}-core"
  core_az_count    = module.core_infra_parameters.map["/core/az_count"]
  core_vpc_cidr    = module.core_infra_parameters.map["/core/vpc_cidr"]
  core_region      = data.aws_region.current.name

  github_token        = module.hub_secrets.secret_map["github_token"]
  repo_url            = module.hub_secrets.secret_map["github_repo_url"]
  ec2_runner_iam_role = module.hub_secrets.secret_map["ec2_runner_iam_role"]
  github_org          = module.hub_secrets.secret_map["github_org"]
  github_repo_name    = module.hub_secrets.secret_map["github_repo_name"]
}
