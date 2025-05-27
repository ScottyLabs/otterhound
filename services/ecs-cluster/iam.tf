# IAM role for ECS task execution
# Used by ECS when starting up containers with Fargate
resource "aws_iam_role" "ecs_task_execution" {
  name = "scottylabs-${var.environment}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# Attach the AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for ECR access
resource "aws_iam_role_policy" "ecs_task_execution_ecr" {
  name = "ecr-access"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",       # Login to ECR
          "ecr:BatchCheckLayerAvailability", # Check if image layers exist
          "ecr:GetDownloadUrlForLayer",      # Download image layers
          "ecr:BatchGetImage"                # Pull container images
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue" # Read database passwords, API keys, etc.
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:scottylabs/${var.environment}/*"
      }
    ]
  })
}

# Default IAM role for ECS tasks
# Give application permissions to access AWS services
resource "aws_iam_role" "ecs_task" {
  name = "scottylabs-${var.environment}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# Basic permissions for applications that can be extended
resource "aws_iam_role_policy" "ecs_task_basic" {
  name = "basic-permissions"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:scottylabs/${var.environment}/*"
      }
    ]
  })
}
