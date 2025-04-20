variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "devopstht"
}

variable "private_subnets" {
  description = "Private Subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public Subnets"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security Group for ECS"
  type        = string
}

variable "order_api_image" {
  description = "Docker image for Order API"
  type        = string
}

variable "processor_image" {
  description = "Docker image for Order Processor"
  type        = string
}

variable "vpc_id" {
  description = "vpc_id"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security Group for ECS cluster ALB"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "ECS Task execution role ARN"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ECS Task task role ARN"
  type        = string
}

variable "orders_table_name" {
  description = "Name of the DynamoDB orders table"
  type        = string
}

variable "inventory_table_name" {
  description = "Name of the DynamoDB inventory table"
  type        = string
}
variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}