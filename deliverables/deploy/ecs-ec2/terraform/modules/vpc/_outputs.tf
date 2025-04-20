output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "Name of the VPC"
  value       = aws_vpc.main.arn
}

output "private_subnets" {
  description = "Private  subnets IDs"
  value       = aws_subnet.private.*.id
}
output "private_route_table_ids" {
  description = "Private  route table IDs"
  value       = aws_route_table.private.*.id
}

output "public_subnets" {
  description = "Public subnets IDs"
  value       = aws_subnet.public.*.id
}
