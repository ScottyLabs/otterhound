terraform {
  # We need this for S3-native state locking
  required_version = ">= 1.10.0"

  backend "s3" {
    key = "bootstrap/github-oidc/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.0.0-beta1" # Update this to "~> 6.0" when available
    }
  }
}

# Reference the env-backends state
data "terraform_remote_state" "env_backends" {
  backend = "s3"
  config = {
    bucket = var.management_bucket_name
    key    = "bootstrap/env-backends/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  # Extract the backend configurations for each environment
  backend_configs = data.terraform_remote_state.env_backends.outputs.backend_configs

  # Allow additional permissions
  additional_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Actions used for services/networking
          "ec2:DescribeAvailabilityZones",
          "ec2:CreateVpc",
          "ec2:CreateTags",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcAttribute",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateInternetGateway",
          "ec2:CreateSubnet",
          "ec2:CreateRouteTable",
          "ec2:CreateSecurityGroup",
          "ec2:AttachInternetGateway",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInternetGateways",
          "ec2:DeleteRouteTable",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteInternetGateway",
          "ec2:DeleteSubnet",
          "ec2:DeleteSecurityGroup",
          "ec2:AllocateAddress",
          "ec2:CreateRoute",
          "ec2:ModifySubnetAttribute",
          "ec2:DescribeAddresses",
          "ec2:AssociateRouteTable",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DescribeAddressesAttribute",
          "ec2:ReleaseAddress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:CreateNatGateway",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeNatGateways",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteNatGateway",

          "rds:CreateDBSubnetGroup",
          "rds:AddTagsToResource",
          "rds:DescribeDBSubnetGroups",
          "rds:ListTagsForResource",
          "rds:DeleteDBSubnetGroup",

          // Additional actions used for services/ecs-cluster
          "iam:CreateRole",
          "iam:TagRole",
          "iam:GetRole",
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:CreateServiceLinkedRole",

          "logs:CreateLogGroup",
          "logs:TagResource",
          "logs:PutRetentionPolicy",
          "logs:DescribeLogGroups",
          "logs:ListTagsForResource",
          "logs:DeleteLogGroup",

          "ecs:CreateCluster",
          "ecs:TagResource",
          "ecs:DescribeClusters",
          "ecs:DeleteCluster",
          "ecs:PutClusterCapacityProviders"
        ]
        Resource = "*"
      }
    ]
  })
}

# Configure providers for each environment account
provider "aws" {
  alias  = "dev"
  region = var.aws_region

  assume_role {
    role_arn = local.backend_configs.dev.role_arn
  }
}

provider "aws" {
  alias  = "staging"
  region = var.aws_region

  assume_role {
    role_arn = local.backend_configs.staging.role_arn
  }
}

provider "aws" {
  alias  = "prod"
  region = var.aws_region

  assume_role {
    role_arn = local.backend_configs.prod.role_arn
  }
}

# GitHub OIDC setup for each environment
module "github_oidc_dev" {
  source = "../../modules/github-oidc"

  providers = {
    aws = aws.dev
  }

  # Used to generate the IAM role name and the state bucket name
  environment = "dev"

  additional_policy_json = local.additional_policy_json
}

module "github_oidc_staging" {
  source = "../../modules/github-oidc"

  providers = {
    aws = aws.staging
  }

  environment = "staging"

  additional_policy_json = local.additional_policy_json
}

module "github_oidc_prod" {
  source = "../../modules/github-oidc"

  providers = {
    aws = aws.prod
  }

  environment = "prod"

  additional_policy_json = local.additional_policy_json
}
