module "hub_infra_parameters" {
  source         = "../modules/ssm-param-reader"
  parameter_list = ["/hub/az_count", "/hub/vpc_cidr", "/hub/vpc_space_cidr"]
}

module "hub_secrets" {
  source    = "../modules/sm-reader"
  secret_id = "hub/infra-secrets"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  az_suffix = ["a", "b", "c", "d", "e", "f"]

  # Main Component Configurations.
  hub_name_prefix     = "${terraform.workspace}.hub"
  region              = data.aws_region.current.name
  hub_az_count        = module.hub_infra_parameters.map["/hub/az_count"]
  hub_vpc_cidr        = module.hub_infra_parameters.map["/hub/vpc_cidr"]
  vpn_cidr            = "10.20.0.0/24"
  vpc_space_cidr      = module.hub_infra_parameters.map["/hub/vpc_space_cidr"]
  hub_public_key      = file("${path.module}/pub_keys/${terraform.workspace}_hub_instance_access.pub")
  github_token        = module.hub_secrets.secret_map["github_token"]
  repo_url            = module.hub_secrets.secret_map["github_repo_url"]
  ec2_runner_iam_role = module.hub_secrets.secret_map["ec2_runner_iam_role"]
  github_org          = module.hub_secrets.secret_map["github_org"]
  github_repo_name    = module.hub_secrets.secret_map["github_repo_name"]
  runner_label        = "main-runner"

  # Core Component Configurations.
  core_workspaces = ["dev"]
  core_vpc_ids = {
    for workspace, state in data.terraform_remote_state.projects :
    workspace => state.outputs.vpc_id
  }
  core_private_subnet_ids = {
    for workspace, state in data.terraform_remote_state.projects :
    workspace => state.outputs.private_subnet_ids
  }
  core_public_subnet_ids = {
    for workspace, state in data.terraform_remote_state.projects :
    workspace => state.outputs.public_subnet_ids
  }
  core_vpc_cidrs = {
    for workspace, state in data.terraform_remote_state.projects :
    workspace => state.outputs.vpc_cidr
  }
  core_availability_zones = {
    for workspace, state in data.terraform_remote_state.projects :
    workspace => state.outputs.availability_zones
  }
  core_public_route_table_id = {
    for workspace, state in data.terraform_remote_state.projects :
    workspace => state.outputs.public_route_table_id
  }
  core_private_route_table_ids = {
    for workspace, state in data.terraform_remote_state.projects :
    workspace => state.outputs.private_route_table_ids
  }
  flattened_core_route_tables = flatten([
    for workspace, route_tables in local.core_private_route_table_ids : [
      for rt_id in route_tables : {
        workspace = workspace
        rt_id     = rt_id
      }
    ]
  ])
}
