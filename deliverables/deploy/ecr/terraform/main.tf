resource "aws_ecr_repository" "order_api" {
  name                 = "${var.environment}-order-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.environment}-order-api"
    Environment = var.environment
    Project     = "THT-DevOps"
    ManagedBy   = "Terraform"
    Service     = "order-api"
  }
}

resource "aws_ecr_repository" "order_processor" {
  name                 = "${var.environment}-order-processor"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.environment}-order-processor"
    Environment = var.environment
    Project     = "THT-DevOps"
    ManagedBy   = "Terraform"
    Service     = "order-processor"
  }
}

# Add lifecycle policy to limit image versions and reduce costs
resource "aws_ecr_lifecycle_policy" "order_api_policy" {
  repository = aws_ecr_repository.order_api.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only 5 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "order_processor_policy" {
  repository = aws_ecr_repository.order_processor.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only 5 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}