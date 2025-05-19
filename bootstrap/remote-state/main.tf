terraform {
  # We need this for S3-native state locking
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.0.0-beta1" # Update this to "~> 6.0" when available
    }
  }
}

# Get current AWS account info
data "aws_caller_identity" "current" {}

# Bootstrap state bucket (for organization setup)
resource "aws_s3_bucket" "bootstrap_state" {
  bucket = "scottylabs-tofu-state-bootstrap-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "ScottyLabs OpenTofu Bootstrap State"
    Environment = "bootstrap"
    ManagedBy   = "opentofu"
  }
}

# Enable versioning for state files
resource "aws_s3_bucket_versioning" "bootstrap_versioning" {
  bucket = aws_s3_bucket.bootstrap_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "bootstrap_encryption" {
  bucket = aws_s3_bucket.bootstrap_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "bootstrap_pab" {
  bucket = aws_s3_bucket.bootstrap_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
