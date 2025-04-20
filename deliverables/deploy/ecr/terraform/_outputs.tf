output "order_api_repository_url" {
  description = "URL of the Order API ECR repository"
  value       = aws_ecr_repository.order_api.repository_url
}

output "order_processor_repository_url" {
  description = "URL of the Order Processor ECR repository"
  value       = aws_ecr_repository.order_processor.repository_url
}
output "order_api_repository_arn" {
  description = "ARN of the Order API ECR repository"
  value       = aws_ecr_repository.order_api.arn
}

output "order_processor_repository_ARN" {
  description = "ARN of the Order Processor ECR repository"
  value       = aws_ecr_repository.order_processor.arn
}