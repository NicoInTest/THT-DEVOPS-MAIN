variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "orders_table_arn" {
  description = "ARN of the Orders DynamoDB table"
  type        = string
}

variable "inventory_table_arn" {
  description = "ARN of the Inventory DynamoDB table"
  type        = string
}

variable "order_api_repo_arn" {
  description = "ARN of Order API repository ARN"
  type        = string
}
variable "order_processor_repo_arn" {
  description = "ARN of Order Processor repository ARN"
  type        = string
}