# Networking Service

This service provides the VPC networking infrastructure for all ScottyLabs services and applications.

## Architecture

Creates a single VPC per environment, with:

* Public subnets (`10.x.0-2.0/24`) intended for load balancers, NAT gateways, bastion hosts, and other public-facing resources.
* Private subnets (`10.x.10-12.0/24`) intended for application containers, Lambda functions, and other private resources.
* Database subnets (`10.x.20-22.0/24`) intended for RDS, Redis, and other isolated resources.

Despite having 2 availability zones (AZs) for dev/staging and 3 AZs for prod, we opt to have these AZs share a single NAT gateway per environment. This is to satisfy the RDS DB subnet group's two-AZ requirements while reducing NAT-related costs.

This service also sets up the internet gateway, route tables, and security groups.

## CIDR Allocation

Each environment's VPC is isolated as follows:

* Dev: `10.0.0.0/16`
* Staging: `10.1.0.0/16`
* Prod: `10.2.0.0/16`

The following is an example subnet layout for `dev`:

```
VPC: 10.0.0.0/16 (65,536 IPs)
├── AZ: us-east-2a
│   ├── Public:   10.0.0.0/24   (256 IPs) -> Internet Gateway
│   ├── Private:  10.0.10.0/24  (256 IPs) -> NAT Gateway
│   └── Database: 10.0.20.0/24  (256 IPs) -> No internet
└── AZ: us-east-2b  
    ├── Public:   10.0.1.0/24   (256 IPs) -> Internet Gateway
    ├── Private:  10.0.11.0/24  (256 IPs) -> NAT Gateway (in AZ A)
    └── Database: 10.0.21.0/24  (256 IPs) -> No internet
```

## Security Groups

There are a few common security groups meant for other services to use:

* `alb_security_group_id` for Application Load Balancers.
  * Inbound: HTTP (80) and HTTPS (443) from anywhere
  * Outbound: To private subnets only

* `apps_security_group_id` for ECS containers, EC2 instances, and appliaction servers.
  * Inbound: From ALBs, inter-app communication
  * Outbound: Full internet access

* `database_security_group_id` for RDS instances and Redis.
  * Inbound: PostgreSQL (`5432`), Redis (`6379`) from apps
  * Outbound: None

* `lambda_security_group_id` for Lambda functions that need VPC access.
  * Inbound: None
  * Outbound: Full internet access + database access

## Usage

Other services can reference this networking infrastructure via remote state:

```terraform
# services/example-service/main.tf
data "aws_vpc" "main" {
  tags = {
    Environment = var.environment
    Service     = "networking"
    ManagedBy   = "opentofu"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    Type = "private"
  }
}

# Example: Security group
data "aws_security_group" "apps" {
  name   = "scottylabs-${var.environment}-apps"
  vpc_id = data.aws_vpc.main.id
}

# Example: ECS service using private subnets
resource "aws_ecs_service" "example" {
  # when using the awsvpc network mode
  network_configuration {
    subnets = data.aws_subnets.private.ids
    security_groups = [data.aws_security_group.apps.id]
  }
}
```
