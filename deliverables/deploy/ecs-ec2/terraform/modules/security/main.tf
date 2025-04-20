# Create an intermediate security group to break the cycle
resource "aws_security_group" "traffic_bridge" {
  name        = "${var.environment}-traffic-bridge-sg"
  description = "Intermediate security group to break circular dependencies"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = { 
    Name        = "${var.environment}-traffic-bridge-sg"
    Environment = var.environment
  }
}

# VPC Endpoints security group for private services access
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.environment}-vpc-endpoints-sg1"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  # Allow HTTPS from private subnets
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
    description = "Allow HTTPS from private subnets"
  }

  # Allow outbound traffic to AWS services
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-vpc-endpoints-sg1"
    Environment = var.environment
  }
}

# Import existing security group instead of creating a new one
# To use this properly, you would need to run:
# terraform import module.security.aws_security_group.ecs_tasks <existing-sg-id>
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.environment}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  # Allow inbound from the bridge security group
  ingress {
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.traffic_bridge.id]
    description     = "Allow inbound traffic from ALB via bridge on dynamic port range"
  }

  # Allow outbound traffic to DynamoDB via public endpoint (no prefix list needed)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS to DynamoDB endpoints and any other AWS services"
  }
  
  # Allow outbound traffic to VPC endpoints
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc_endpoints.id]
    description     = "Allow HTTPS to VPC endpoints"
  }

  # Allow outbound traffic to the internet via bridge
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = { 
    Name        = "${var.environment}-ecs-tasks-sg"
    Environment = var.environment
  }
  
  # Prevent Terraform from recreating this resource
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      # Ignore all attributes to just use the existing security group
      description,
      name,
      ingress,
      egress,
      tags
    ]
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  # HTTP ingress - Consider restricting to specific IPs if possible in a production environment
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere (for demonstration purposes)"
  }
  
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow HTTP from anywhere IPv6 (for demonstration purposes)"
  }

  # Allow egress to the bridge security group instead of directly to ECS tasks
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.traffic_bridge.id]
    description     = "Allow all traffic via bridge security group"
  }

  tags = { 
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
  }
}
