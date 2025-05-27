# ECS Cluster
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

# IAM Roles
output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role (required for all ECS services)"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.name
}

output "default_task_role_arn" {
  description = "ARN of the default ECS task role (can be used or overridden by services)"
  value       = aws_iam_role.ecs_task.arn
}

output "default_task_role_name" {
  description = "Name of the default ECS task role"
  value       = aws_iam_role.ecs_task.name
}

# CloudWatch
output "log_group_name" {
  description = "Name of the CloudWatch log group for ECS containers"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group for ECS containers"
  value       = aws_cloudwatch_log_group.ecs.arn
}

# Capacity Providers
output "capacity_providers" {
  description = "List of capacity providers configured for the cluster"
  value       = aws_ecs_cluster_capacity_providers.main.capacity_providers
}
