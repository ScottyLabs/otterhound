terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.0.0-beta1" # Update this to "~> 6.0" when available
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Enable AWS Organizations
resource "aws_organizations_organization" "main" {
  feature_set = "ALL"

  aws_service_access_principals = [
    "sso.amazonaws.com",             # AWS SSO/IAM Identity Center
    "account.amazonaws.com"          # AWS Account Management
  ]
}

# Create Organizational Units for environments
resource "aws_organizations_organizational_unit" "environments" {
  name      = "Environments"
  parent_id = aws_organizations_organization.main.roots[0].id # Parent is the root

  tags = {
    # dev, staging, and prod; AWS doesn't allow parenthesis or commas in tags
    Purpose = "Environment accounts"
  }
}

# Create Development Account
resource "aws_organizations_account" "dev" {
  name      = "ScottyLabs-Dev"
  email     = "aws-dev@scottylabs.org"
  parent_id = aws_organizations_organizational_unit.environments.id

  # A role for the management account to assume
  # to perform admin actions in the dev account
  role_name = "OrganizationAccountAccessRole"

  tags = {
    Environment = "dev"
    Purpose     = "Development environment"
  }

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}

# Create Staging Account
resource "aws_organizations_account" "staging" {
  name      = "ScottyLabs-Staging"
  email     = "aws-staging@scottylabs.org"
  parent_id = aws_organizations_organizational_unit.environments.id

  role_name = "OrganizationAccountAccessRole"

  tags = {
    Environment = "staging"
    Purpose     = "Staging environment"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Create Production Account
resource "aws_organizations_account" "prod" {
  name      = "ScottyLabs-Prod"
  email     = "aws-prod@scottylabs.org"
  parent_id = aws_organizations_organizational_unit.environments.id

  role_name = "OrganizationAccountAccessRole"

  tags = {
    Environment = "prod"
    Purpose     = "Production environment"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Get management account info
data "aws_caller_identity" "current" {}
