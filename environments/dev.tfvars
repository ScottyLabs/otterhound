# Networking
vpc_cidr           = "10.0.0.0/16"
az_count           = 2
single_nat_gateway = true

# ECS Cluster
log_retention_days        = 7
enable_container_insights = true
enable_fargate_spot       = true
fargate_spot_weight       = 80

# Environment
environment = "dev"
