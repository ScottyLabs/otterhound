# Networking
vpc_cidr           = "10.2.0.0/16"
az_count           = 3
single_nat_gateway = true

# ECS Cluster
log_retention_days        = 90
enable_container_insights = true
enable_fargate_spot       = false
fargate_spot_weight       = 0

# Environment
environment = "prod"
