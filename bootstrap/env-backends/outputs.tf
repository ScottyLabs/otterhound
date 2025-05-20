output "state_bucket_names" {
  description = "S3 bucket names for each environment's state"
  value = {
    dev     = aws_s3_bucket.dev_state.bucket
    staging = aws_s3_bucket.staging_state.bucket
    prod    = aws_s3_bucket.prod_state.bucket
  }
}

output "backend_configs" {
  description = "Backend configurations for each environment"
  value = {
    dev = {
      bucket   = aws_s3_bucket.dev_state.bucket
      role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.account_ids.dev}:role/OrganizationAccountAccessRole"
    }
    staging = {
      bucket   = aws_s3_bucket.staging_state.bucket
      role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.account_ids.staging}:role/OrganizationAccountAccessRole"
    }
    prod = {
      bucket   = aws_s3_bucket.prod_state.bucket
      role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.account_ids.prod}:role/OrganizationAccountAccessRole"
    }
  }
}
