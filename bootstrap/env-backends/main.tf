terraform {
  # We need this for S3-native state locking
  required_version = ">= 1.10.0"

  backend "s3" {
    key = "bootstrap/env-backends/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.0.0-beta1" # Update this to "~> 6.0" when available
    }
  }
}

# Configure providers for each environment account
provider "aws" {
  alias  = "dev"
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids.dev}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias  = "staging"
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids.staging}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias  = "prod"
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids.prod}:role/OrganizationAccountAccessRole"
  }
}

# S3 bucket for each environment's state
resource "aws_s3_bucket" "dev_state" {
  provider = aws.dev
  bucket   = "scottylabs-tofu-state-dev-${var.account_ids.dev}"

  tags = {
    Name        = "ScottyLabs OpenTofu Dev State"
    Environment = "dev"
    ManagedBy   = "opentofu"
  }
}

resource "aws_s3_bucket" "staging_state" {
  provider = aws.staging
  bucket   = "scottylabs-tofu-state-staging-${var.account_ids.staging}"

  tags = {
    Name        = "ScottyLabs OpenTofu Staging State"
    Environment = "staging"
    ManagedBy   = "opentofu"
  }
}

resource "aws_s3_bucket" "prod_state" {
  provider = aws.prod
  bucket   = "scottylabs-tofu-state-prod-${var.account_ids.prod}"

  tags = {
    Name        = "ScottyLabs OpenTofu Prod State"
    Environment = "prod"
    ManagedBy   = "opentofu"
  }
}

# Enable versioning for state files
resource "aws_s3_bucket_versioning" "dev_versioning" {
  provider = aws.dev
  bucket   = aws_s3_bucket.dev_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "staging_versioning" {
  provider = aws.staging
  bucket   = aws_s3_bucket.staging_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "prod_versioning" {
  provider = aws.prod
  bucket   = aws_s3_bucket.prod_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "dev_encryption" {
  provider = aws.dev
  bucket   = aws_s3_bucket.dev_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "staging_encryption" {
  provider = aws.staging
  bucket   = aws_s3_bucket.staging_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "prod_encryption" {
  provider = aws.prod
  bucket   = aws_s3_bucket.prod_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "dev_pab" {
  provider = aws.dev
  bucket   = aws_s3_bucket.dev_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "staging_pab" {
  provider = aws.staging
  bucket   = aws_s3_bucket.staging_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "prod_pab" {
  provider = aws.prod
  bucket   = aws_s3_bucket.prod_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
