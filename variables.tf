variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "access_key" {
  description = "The AWS access key"
  type        = string
}
variable "secret_key" {
  description = "The AWS secret key"
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string

}


variable "instance_type" {
  description = "The type of EC2 instance to launch"
  type        = string
}
variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "subnet_cidr" {
  description = "The CIDR block for the Subnet"
  type        = string
}

variable "env" {
  description = "The environment for the security group"
  type        = string

}

variable "allowed_ports_map" {
  description = "The allowed ports for the security group"
  type        = map(number)
}
variable "base_instance_count" {
  description = "The number of EC2 instances to launch"
  type        = number
}

variable "project_name" {

  description = "The name of the project"
  type        = string
}

variable "owner" {
  description = "The owner of the resources"
  type        = string

}

