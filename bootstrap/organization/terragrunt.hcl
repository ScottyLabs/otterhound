dependency "backend" {
  config_path = "../backend"
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = dependency.backend.outputs.bootstrap_bucket_name
    key          = "bootstrap/organization/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
    encrypt      = true
  }
}
