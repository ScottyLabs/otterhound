include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  aws_region = include.root.locals.aws_region
}

dependency "backend" {
  config_path = "../backend"
}

dependency "organization" {
  config_path = "../organization"
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = dependency.backend.outputs.bootstrap_bucket_name
    key          = "bootstrap/env-backends/terraform.tfstate"
    region       = local.aws_region
    use_lockfile = true
    encrypt      = true
  }
}

inputs = {
  account_ids = dependency.organization.outputs.account_ids
  aws_region  = local.aws_region
}
