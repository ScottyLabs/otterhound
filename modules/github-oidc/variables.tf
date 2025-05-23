variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "github_repository_conditions" {
  description = "List of GitHub repository conditions for OIDC trust"
  type        = list(string)
  # The "sub" claim format is: "repo:<owner>/<repo>:ref:refs/heads/<branch>"
  default = ["repo:ScottyLabs/infrastructure:*"]
}

variable "additional_policy_json" {
  description = "Optional additional IAM policy JSON for environment-specific permissions"
  type        = string
  default     = null
}
