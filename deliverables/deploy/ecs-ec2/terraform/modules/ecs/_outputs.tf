output "order_api_alb_dns_name" {
  description = "DNS name of the Order API load balancer"
  value       = aws_lb.order_api.dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "order_api_service_name" {
  description = "Name of the Order API ECS service"
  value       = aws_ecs_service.order_api.name
}

output "order_processor_service_name" {
  description = "Name of the Order Processor ECS service"
  value       = aws_ecs_service.order_processor.name
}

output "service_discovery_namespace" {
  description = "Service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.name
}
