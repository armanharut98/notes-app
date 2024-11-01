terraform {
  backend "s3" {
    bucket         = "aca-infra-states"
    key            = "tf-projects/core-infra-state.tfstate"
    region         = "us-east-1"
    dynamodb_table = "aca-infra-state-lock"
  }
}

provider "aws" {
  region = "us-east-1"
}
