variable "account_ids" {
  description = "Account IDs from organization"
  type = object({
    management = string
    dev        = string
    staging    = string
    prod       = string
  })
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-2"
}
