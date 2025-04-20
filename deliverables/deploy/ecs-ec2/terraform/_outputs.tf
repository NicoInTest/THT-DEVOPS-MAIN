output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.ecs.order_api_alb_dns_name
}

output "dynamodb_orders_table" {
  description = "Name of the DynamoDB orders table"
  value       = module.dynamodb.orders_table_name
}

output "dynamodb_inventory_table" {
  description = "Name of the DynamoDB inventory table"
  value       = module.dynamodb.inventory_table_name
}