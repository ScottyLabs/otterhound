variable "management_state_bucket" {
  description = "Name of the management S3 bucket containing organization state"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-2"
}
