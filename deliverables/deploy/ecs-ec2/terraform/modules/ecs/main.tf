resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  service_connect_defaults {
    namespace = aws_service_discovery_private_dns_namespace.main.arn
  }
}
###################### ECS SERVICES AND TASK DEFINITIONS HERE

# Launch template for EC2 instances (replacing launch configuration)
resource "aws_launch_template" "ecs_instances" {
  name_prefix   = "${var.environment}-ecs-instances-"
  image_id      = "ami-0eb11ab33f229b26c" # Amazon ECS-optimized AMI for eu-west-1
  instance_type = var.instance_type
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }
  
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ecs_security_group_id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for ECS instances
#resource "aws_autoscaling_group" "ecs_instances" {
#  name                = "${var.environment}-ecs-asg"
#  min_size            = 1
#  max_size            = 2
#  desired_capacity    = 1
#  vpc_zone_identifier = var.private_subnets
#  
#  # Use launch template instead of launch configuration
#  launch_template {
#    id      = aws_launch_template.ecs_instances.id
#    version = "$Latest"
#  }
#
#  tag {
#    key                 = "Name"
#    value               = "${var.environment}-ecs-instance"
#    propagate_at_launch = true
#  }
#
#  tag {
#    key                 = "AmazonECSManaged"
#    value               = true
#    propagate_at_launch = true
#  }
#  
#  lifecycle {
#    create_before_destroy = true
#    ignore_changes = [
#      desired_capacity,
#      min_size,
#      max_size,
#     tag
#    ]
#  }
#}

# Create a separate target group for the order_api ALB
resource "aws_lb_target_group" "order_api_tg" {
  vpc_id      = var.vpc_id
  name        = "${var.environment}-order-api-main-tg"
  port        = 8000
  protocol    = "HTTP"
  target_type = "instance"

  health_check {
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

# ALB for Order API
resource "aws_lb" "order_api" {
  name               = "${var.environment}-order-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnets

  lifecycle {
    create_before_destroy = true
    ignore_changes = [name, security_groups, subnets, tags]
  }

  tags = {
    Name        = "${var.environment}-order-api-alb"
    Environment = var.environment
  }
}

# HTTP Listener for Order API
resource "aws_lb_listener" "order_api_http" {
  load_balancer_arn = aws_lb.order_api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order_api_tg.arn
  }

  # This is to avoid resource recreation if configuration changes
  lifecycle {
    ignore_changes = [default_action, load_balancer_arn, port, protocol]
    create_before_destroy = true
  }
}

# ECS Task Definition - Order API
resource "aws_ecs_task_definition" "order_api" {
  family                   = "${var.environment}-order-api"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "order-api"
      image     = var.order_api_image
      essential = true
      memory         = 512
      memoryReservation = 256
      
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 0
          protocol      = "tcp"
          name          = "order-api-port"
        }
      ]
      
      environment = [
        { name = "AWS_DEFAULT_REGION", value = var.aws_region },
        { name = "DYNAMODB_TABLE", value = var.orders_table_name },
        { name = "DYNAMODB_ENDPOINT", value = "https://dynamodb.${var.aws_region}.amazonaws.com" },
        { name = "ORDER_PROCESSOR_URL", value = "http://order-processor:8000" },
        { name = "SRV_ENDPOINT", value = "order-processor.${var.environment}.local" }
      ]
      
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.environment}/order-api"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Service - Order API
resource "aws_ecs_service" "order_api" {
  name            = "${var.environment}-order-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_api.arn
  desired_count   = 1
  
  load_balancer {
    target_group_arn = aws_lb_target_group.order_api_tg.arn
    container_name   = "order-api"
    container_port   = 8000
  }
  
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
  }

  service_registries {
    registry_arn = aws_service_discovery_service.order_api.arn
    container_name = "order-api"
    container_port = 8000
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      task_definition,
      load_balancer,
      desired_count,
      capacity_provider_strategy,
      service_registries
    ]
  }

  depends_on = [aws_lb_listener.order_api_http]
}

# ECS Task Definition - Order Processor
resource "aws_ecs_task_definition" "order_processor" {
  family                   = "${var.environment}-order-processor"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "order-processor"
      image     = var.processor_image
      essential = true
      memory         = 512
      memoryReservation = 256
      
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 0
          protocol      = "tcp"
          name          = "order-processor-port"
        }
      ]
      
      environment = [
        { name = "AWS_DEFAULT_REGION", value = var.aws_region },
        { name = "DYNAMODB_TABLE", value = var.inventory_table_name },
        { name = "DYNAMODB_ENDPOINT", value = "https://dynamodb.${var.aws_region}.amazonaws.com" }
      ]
      
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.environment}/order-processor"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Service - Order Processor
resource "aws_ecs_service" "order_processor" {
  name            = "${var.environment}-order-processor"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_processor.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.order_processor.arn
    container_name = "order-processor"
    container_port = 8000
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "order_api" {
  name              = "/ecs/${var.environment}/order-api"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "order_processor" {
  name              = "/ecs/${var.environment}/order-processor"
  retention_in_days = 7
}
