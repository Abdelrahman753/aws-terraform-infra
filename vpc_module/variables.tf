variable "cidr_block" {
    description = "The CIDR block for the VPC"
    type        = string
}

variable "project_name" {
    description = "The name of the VPC"
    type        = string
  
}
variable "env" {
    description = "The environment for the VPC"
    type        = string
}