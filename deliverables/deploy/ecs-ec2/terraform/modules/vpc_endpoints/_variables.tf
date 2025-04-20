variable "environment" {
  description = "Environment name"
  type        = string
  default     = "devopstht"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "VPC Private Subnets IDS"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "Private Routes table IDs "
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ECS security group ID "
  type        = string
}

