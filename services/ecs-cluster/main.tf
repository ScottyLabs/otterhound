terraform {
  # We need this for S3-native state locking
  required_version = ">= 1.10.0"

  backend "s3" {
    key = "services/ecs-cluster/terraform.tfstate"
  }

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

locals {
  # Common tags for all resources
  tags = {
    Environment = var.environment
    ManagedBy   = "opentofu"
    Service     = "ecs-cluster"
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/scottylabs-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-ecs-logs"
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "scottylabs-${var.environment}"

  # Enable container insights for monitoring
  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-ecs"
  })
}

# Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    # Always have at least 1 regular Fargate task for stability
    base = 1

    # Calculate weight to achieve desired spot percentage
    # e.g. if 80% spot desired, use 20% regular weight
    weight = 100 - (var.enable_fargate_spot ? var.fargate_spot_weight : 0)

    capacity_provider = "FARGATE"
  }

  # Add spot capacity if enabled
  dynamic "default_capacity_provider_strategy" {
    for_each = var.enable_fargate_spot ? [1] : []
    content {
      base              = 0
      weight            = var.fargate_spot_weight
      capacity_provider = "FARGATE_SPOT"
    }
  }
}
