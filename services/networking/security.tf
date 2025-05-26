# Security Group for Application Load Balancers
resource "aws_security_group" "alb" {
  name        = "scottylabs-${var.environment}-alb"
  description = "Security group for Application Load Balancers"
  vpc_id      = aws_vpc.main.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80 # Default port for HTTP
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443 # Default port for HTTPS
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # Outbound to private subnets
  egress {
    from_port   = 0
    to_port     = 65535 # All ports
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private[*].cidr_block
    description = "To private subnets"
  }

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-alb"
  })
}

# Security Group for ECS Tasks / Application Servers
resource "aws_security_group" "apps" {
  name        = "scottylabs-${var.environment}-apps"
  description = "Security group for application containers and servers"
  vpc_id      = aws_vpc.main.id

  # Allow inbound from ALBs
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "From ALBs"
  }

  # Allow apps to talk to each other
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Inter-app communication"
  }

  # Allow outbound internet access
  egress {
    from_port   = 0
    to_port     = 0    # All ports
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-apps"
  })
}

# Security Group for Databases
resource "aws_security_group" "database" {
  name        = "scottylabs-${var.environment}-database"
  description = "Security group for databases"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL from apps
  ingress {
    from_port       = 5432
    to_port         = 5432 # Default port for PostgreSQL
    protocol        = "tcp"
    security_groups = [aws_security_group.apps.id]
    description     = "PostgreSQL from apps"
  }

  # Redis from apps
  ingress {
    from_port       = 6379
    to_port         = 6379 # Default port for Redis
    protocol        = "tcp"
    security_groups = [aws_security_group.apps.id]
    description     = "Redis from apps"
  }

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-database"
  })
}

# Security Group for Lambda Functions (when in VPC)
resource "aws_security_group" "lambda" {
  name        = "scottylabs-${var.environment}-lambda"
  description = "Security group for Lambda functions in VPC"
  vpc_id      = aws_vpc.main.id

  # Allow outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.tags, {
    Name = "scottylabs-${var.environment}-lambda"
  })
}

# Allow Lambda to access databases
resource "aws_security_group_rule" "lambda_to_database" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda.id   # Which security group is allowed to send traffic
  security_group_id        = aws_security_group.database.id # Which security group the rule is being added to
  description              = "PostgreSQL from Lambda"
}
