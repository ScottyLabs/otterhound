terraform {
  # We need this for S3-native state locking
  required_version = ">= 1.10.0"

  backend "s3" {
    key = "services/networking/terraform.tfstate"
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

# To avoid hardcoding specific AZ names like us-east-2a, etc.
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Use the specified number of AZs
  used_az_count      = min(var.az_count, length(data.aws_availability_zones.available.names))
  availability_zones = slice(data.aws_availability_zones.available.names, 0, local.used_az_count)

  # Common tags for all resources
  tags = {
    Environment = var.environment
    ManagedBy   = "opentofu"
    Service     = "networking"
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  # Most services need DNS to function properly
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-igw"
  })
}

# Public subnets (for ALBs, NAT Gateways, Bastion hosts, etc.)
resource "aws_subnet" "public" {
  count = length(local.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index) # Creates 10.x.0.0/24, 10.x.1.0/24, 10.x.2.0/24
  availability_zone = local.availability_zones[count.index]

  # Assign public IPv4 addresses to instances launched in this subnet
  # Different from the EIP (not static, changes when instances are stopped and started)
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-public-${local.availability_zones[count.index]}"
    Type = "public"
  })
}

# Private Subnets (for ECS, Lambda, application servers)
resource "aws_subnet" "private" {
  count = length(local.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10) # Creates 10.x.10.0/24, 10.x.11.0/24, 10.x.12.0/24
  availability_zone = local.availability_zones[count.index]

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-private-${local.availability_zones[count.index]}"
    Type = "private"
  })
}

# Database Subnets (for RDS, etc.)
resource "aws_subnet" "database" {
  count = length(local.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20) # Creates 10.x.20.0/24, 10.x.21.0/24, 10.x.22.0/24
  availability_zone = local.availability_zones[count.index]

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-database-${local.availability_zones[count.index]}"
    Type = "database"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  # One EIP per availability zone (per NAT gateway)
  count = length(local.availability_zones)

  # The EIP will be used within the VPC (EC2-VPC platform)
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-nat-eip-${local.availability_zones[count.index]}"
  })
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  # One NAT gateway per availability zone
  count = length(local.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  # NAT gateway needs the internet gateway to route traffic to the internet
  depends_on = [aws_internet_gateway.main]

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-nat-${local.availability_zones[count.index]}"
  })
}

# Public Route Table
resource "aws_route_table" "public" {
  # Each subnet should have a route table association
  vpc_id = aws_vpc.main.id

  # Send and receive traffic from the internet
  route {
    cidr_block = "0.0.0.0/0"                  # All internet traffic
    gateway_id = aws_internet_gateway.main.id # Go directly to internet gateway
  }

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-public-rt"
  })
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables
resource "aws_route_table" "private" {
  count = length(local.availability_zones)

  vpc_id = aws_vpc.main.id

  # Receive traffic from public resources, but not from the internet
  # Send outbound traffic to internet via NAT gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id # Go to NAT gateway first
  }

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-private-rt-${local.availability_zones[count.index]}"
  })
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Database Route Table
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  # No internet access, can only be reached from within the VPC

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-database-rt"
  })
}

# Database Route Table Associations
resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# Database Subnet Group
# Required for RDS instances to be created in the VPC
resource "aws_db_subnet_group" "main" {
  name       = "scottylabs-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-db-subnet-group"
  })
}
