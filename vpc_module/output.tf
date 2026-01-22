output "vpc_id" {
    description = "The ID of the VPC"
    value       = aws_vpc.imported_vpc.id
}