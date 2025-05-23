terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.0.0-beta1" # Update this to "~> 6.0" when available
    }
  }
}

# Get environment account's ID
data "aws_caller_identity" "current" {}

locals {
  # Name for the IAM role
  role_name = "GitHubActions-OpenTofu-${title(var.environment)}"

  # Auto-discover bucket name using environment account's ID
  account_id = data.aws_caller_identity.current.account_id
  state_bucket_name = "scottylabs-tofu-state-${var.environment}-${local.account_id}"
  state_bucket_arn = "arn:aws:s3:::${local.state_bucket_name}"

  # Common tags for all resources
  tags = {
    ManagedBy   = "opentofu"
    Repository  = "ScottyLabs/infrastructure"
    Purpose     = "GitHub Actions OIDC"
    Environment = var.environment
  }
}

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  tags = local.tags
}

# IAM role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          # Use StringLike to support the wildcard in the repository condition
          StringLike = {
            "token.actions.githubusercontent.com:sub" = var.github_repository_conditions
          }
        }
      }
    ]
  })

  tags = local.tags
}

# Policy for OpenTofu state bucket access
resource "aws_iam_policy" "opentofu_state_access" {
  name        = "${local.role_name}-state-access"
  description = "Allows access to OpenTofu state bucket for ${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ]
        Resource = local.state_bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${local.state_bucket_arn}/*"
      }
    ]
  })

  tags = local.tags
}

# Additional policy for environment-specific permissions
resource "aws_iam_policy" "environment_access" {
  count = var.additional_policy_json != null ? 1 : 0

  name        = "${local.role_name}-environment-access"
  description = "Environment-specific permissions for ${var.environment}"

  policy = var.additional_policy_json

  tags = local.tags
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "state_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.opentofu_state_access.arn
}

resource "aws_iam_role_policy_attachment" "environment_access" {
  count = var.additional_policy_json != null ? 1 : 0

  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.environment_access[0].arn
}
