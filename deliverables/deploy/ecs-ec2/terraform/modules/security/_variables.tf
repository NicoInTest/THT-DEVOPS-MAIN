variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "vpc_id"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

