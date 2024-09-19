
output "name" {
  description = "The name of the VPC"
  value       = aws_vpc.main.tags.Name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "azs" {
  description = "A list of availability zones specified for the region"
  value       = var.vpc_azs
}

output "private_subnet_ids" {
  description = "A list of the private subnet IDs"
  value       = aws_subnet.private_subnet[*].id
}

output "private_subnet_cidr_blocks" {
  description = "A list of the private subnet CIDR blocks"
  value       = aws_subnet.private_subnet[*].cidr_block
}

output "public_subnet_ids" {
  description = "A list of the public subnet IDs"
  value       = aws_subnet.public_subnet[*].id
}

output "public_subnet_cidr_blocks" {
  description = "A list of the public subnet CIDR blocks"
  value       = aws_subnet.public_subnet[*].cidr_block
}
