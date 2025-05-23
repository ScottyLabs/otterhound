variable "management_bucket_name" {
  description = "S3 bucket name for management account"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-2"
}
