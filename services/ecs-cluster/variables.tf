variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30

  validation {
    # The log retention periods AWS supports
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.log_retention_days)

    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the ECS cluster"
  type        = bool
  default     = true
}

variable "enable_fargate_spot" {
  description = "Enable Fargate Spot capacity provider for cost optimization"
  type        = bool
  default     = false
}

variable "fargate_spot_weight" {
  description = "Weight for Fargate Spot capacity provider (0-100)"
  type        = number
  default     = 80

  validation {
    condition     = var.fargate_spot_weight >= 0 && var.fargate_spot_weight <= 100
    error_message = "Fargate Spot weight must be between 0 and 100."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-2"
}
