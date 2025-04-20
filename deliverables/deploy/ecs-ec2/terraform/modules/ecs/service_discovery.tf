# AWS Service Connect configuration for ECS services
# This allows tasks to resolve DNS names in the private namespace

# Create a private DNS namespace for service discovery
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.environment}.local"
  vpc         = var.vpc_id
  description = "Private DNS namespace for service discovery"
}

# Service Discovery for order-processor service
resource "aws_service_discovery_service" "order_processor" {
  name = "order-processor"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "SRV"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Service Discovery for order-api service
resource "aws_service_discovery_service" "order_api" {
  name = "order-api"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "SRV"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}