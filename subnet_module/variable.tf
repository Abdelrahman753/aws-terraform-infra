variable "subnet_cider" {
    description = "The CIDR block for the Subnet"
    type        = string
}

variable "region" {
    description = "The AWS region to deploy resources in"
    type        = string
}
variable "vpc_id" {
    description = "The ID of the VPC"
    type        = string
  
}

