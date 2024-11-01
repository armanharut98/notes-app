module "core_infra_parameters" {
  source         = "../modules/ssm-param-reader"
  parameter_list = ["/core/az_count", "/core/vpc_cidr"]
}

data "aws_region" "current" {}

locals {
  project_name = "core_infra"
  az_suffix    = ["a", "b", "c", "d", "e", "f"]

  core_name_prefix = "${terraform.workspace}.core"
  core_az_count    = module.core_infra_parameters.map["/core/az_count"]
  core_vpc_cidr    = module.core_infra_parameters.map["/core/vpc_cidr"]
  core_region      = data.aws_region.current.name
}
