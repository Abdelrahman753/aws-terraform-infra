variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "routes" {
  description = "List of routes"
  type = list(object({
    cidr_block = string
    gateway_id = optional(string)
    nat_gateway_id = optional(string)
  }))
}

variable "subnet_ids" {
  description = "Subnets to associate with this route table"
  type        = list(string)
}

variable "name" {
  description = "Route table name"
  type        = string
}
