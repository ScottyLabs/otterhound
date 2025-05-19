output "account_ids" {
  description = "All AWS account IDs"
  value = {
    management = data.aws_caller_identity.current.account_id
    dev        = aws_organizations_account.dev.id
    staging    = aws_organizations_account.staging.id
    prod       = aws_organizations_account.prod.id
  }
}
