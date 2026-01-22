variable "Security-name" {
    description = "The name of the security group"
    type        = string
}
variable "vpc_id" {
    description = "The ID of the VPC"
    type        = string
}

variable "ingress_rules" {
    description = "List of ingress rules for the security group"
    type        = list(object({
        from_port   = number
        to_port     = number
        protocol    = string
        cidr_blocks = list(string)
    }))
  
}

variable "egress_rules" {
    description = "List of egress rules for the security group"
    type        = list(object({
        from_port   = number
        to_port     = number
        protocol    = string
        cidr_blocks = list(string)
    }))
}

variable "env" {
    description = "The environment for the security group"
    type        = string
  
}