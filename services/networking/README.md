# Networking Service

This service provides the VPC networking infrastructure for all ScottyLabs services and applications.

## Architecture

Creates a single VPC per environment, with:

* Public subnets (`10.x.0-2.0/24`) intended for load balancers, NAT gateways, bastion hosts, and other public-facing resources.
* Private subnets (`10.x.10-12.0/24`) intended for application containers, Lambda functions, and other private resources.
* Database subnets (`10.x.20-22.0/24`) intended for RDS, Redis, and other isolated resources.

For cost purposes, we opt for a single availability zone (AZ) per VPC. We have per-AZ NAT gateways, i.e. one per VPC.

This service also sets up the internet gateway, route tables, and security groups.

## CIDR Allocation

Each environment's VPC is isolated as follows:

* Dev: `10.0.0.0/16`
* Staging: `10.1.0.0/16`
* Prod: `10.2.0.0/16`

The following is an example subnet layout for `dev`:

```
VPC: 10.0.0.0/16 (65,536 IPs)
└── AZ: us-east-2a
    ├── Public:   10.0.0.0/24   (256 IPs) -> Internet Gateway
    ├── Private:  10.0.10.0/24  (256 IPs) -> NAT Gateway
    └── Database: 10.0.20.0/24  (256 IPs) -> No internet
```

## Security Groups

There are a few common security groups meant for other services to use:

* `alb_security_group_id` for Application Load Balancers.
** Inbound: HTTP (80) and HTTPS (443) from anywhere
** Outbound: To private subnets only

* `apps_security_group_id` for ECS containers, EC2 instances, and appliaction servers.
** Inbound: From ALBs, inter-app communication
** Outbound: Full internet access

* `database_security_group_id` for RDS instances and Redis.
** Inbound: PostgreSQL (`5432`), Redis (`6379`) from apps
** Outbound: None

* `lambda_security_group_id` for Lambda functions that need VPC access.
** Inbound: None
** Outbound: Full internet access + database access

## Usage

Other services can reference this networking infrastructure via remote state:

```terraform
# services/example-service/main.tf
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "scottylabs-tofu-state-${var.environment}-${data.aws_caller_identity.current.account_id}"
    key    = "services/networking/terraform.tfstate"
    region = "us-east-2"
  }
}

# Use the VPC and subnets
resource "aws_security_group" "example" {
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
}
```
