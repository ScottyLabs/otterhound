output "github_actions_role_arns" {
  description = "IAM role ARNs for GitHub Actions in each environment"
  value = {
    dev     = module.github_oidc_dev.role_arn
    staging = module.github_oidc_staging.role_arn
    prod    = module.github_oidc_prod.role_arn
  }
}

output "github_actions_role_names" {
  description = "IAM role names for GitHub Actions in each environment"
  value = {
    dev     = module.github_oidc_dev.role_name
    staging = module.github_oidc_staging.role_name
    prod    = module.github_oidc_prod.role_name
  }
}

output "oidc_provider_arns" {
  description = "GitHub OIDC provider ARNs in each environment"
  value = {
    dev     = module.github_oidc_dev.oidc_provider_arn
    staging = module.github_oidc_staging.oidc_provider_arn
    prod    = module.github_oidc_prod.oidc_provider_arn
  }
}

# Output in a format ready for GitHub Actions secrets
output "github_secrets_format" {
  description = "Role ARNs formatted for GitHub Actions secrets"
  value = {
    AWS_ROLE_TO_ASSUME_DEV     = module.github_oidc_dev.role_arn
    AWS_ROLE_TO_ASSUME_STAGING = module.github_oidc_staging.role_arn
    AWS_ROLE_TO_ASSUME_PROD    = module.github_oidc_prod.role_arn
  }
}
