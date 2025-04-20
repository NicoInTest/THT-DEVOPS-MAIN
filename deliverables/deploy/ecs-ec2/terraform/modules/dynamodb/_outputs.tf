output "orders_table_name" {
  description = "Name of the DynamoDB orders table"
  value       = aws_dynamodb_table.orders.name
}
output "orders_table_arn" {
  description = "ARN of the DynamoDB orders table"
  value       = aws_dynamodb_table.orders.arn
}

output "inventory_table_name" {
  description = "Name of the DynamoDB inventory table"
  value       = aws_dynamodb_table.inventory.name
}
output "inventory_table_arn" {
  description = "ARN of the DynamoDB inventory table"
  value       = aws_dynamodb_table.inventory.arn
}
