# ECS Cluster Service

This service provides a shared Amazon ECS cluster for running containerized applications across all ScottyLabs services.

## Architecture

* Creates a Fargate-based cluster with optional Fargate Spot for cost optimization
* Creates a centralized CloudWatch log group for each environment, located at `/ecs/scottylabs-{environment}`
* Configures execution and task IAM roles with the appropriate permissions

## Roles

* The task execution role `ecs_task_execution` includes the permissions required to run containers (ECR access, log writing, and secrets access).
* The default task role `ecs_task` includes basic application permissions that should be extended as needed.

Secrets Manager access is also scoped to environment under `scottylabs/{environment}/*`.

## Configuration

The table below includes the selected values for each environment.

| Variable | Description | Default | Dev | Staging | Prod |
|----------|-------------|---------|-----|---------|------|
| `log_retention_days` | CloudWatch log retention | 30 | 7 | 30 | 90 |
| `enable_container_insights` | Enable detailed monitoring | true | true | true | true |
| `enable_fargate_spot` | Use spot instances | false | true | true | false |
| `fargate_spot_weight` | Percentage of spot usage | 80 | 80 | 80 | 0 |

## Usage

Other services can reference this service via data blocks:

```terraform
# services/example-service/main.tf

# Reference the ECS cluster
data "aws_ecs_cluster" "main" {
  cluster_name = "scottylabs-${var.environment}"
}

# Reference IAM roles
data "aws_iam_role" "ecs_task_execution" {
  name = "scottylabs-${var.environment}-ecs-task-execution"
}

data "aws_iam_role" "ecs_task" {
  name = "scottylabs-${var.environment}-ecs-task"
}

# Reference log group
data "aws_cloudwatch_log_group" "ecs" {
  name = "/ecs/scottylabs-${var.environment}"
}

# Example: Complete ECS service
resource "aws_ecs_task_definition" "example-app" {
  family                   = "example-app-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  # Use shared roles
  execution_role_arn = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn      = data.aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "example-app"
    image = "example-app:latest"

    # Use shared log group
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = data.aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "example-app"
      }
    }
  }])
}

resource "aws_ecs_service" "example-app" {
  name            = "example-app"
  cluster         = data.aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2  # Run 2 instances for redundancy

  # Uses cluster's default capacity provider strategy (FARGATE + FARGATE_SPOT mix)
}
```
