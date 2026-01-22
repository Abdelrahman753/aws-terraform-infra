variable "instance_type" { 
    description = "The type of EC2 instance to launch"
    type        = string
}
variable "subnet_id" {
    description = "The ID of the Subnet where the EC2 instance will be launched"
    type        = string
}

variable "ami" {
    description = "The AMI ID for the EC2 instance"
    type        = string
  
}
variable "security_group_id" {
    description = "The ID of the security group to associate with the EC2 instance"
    type        = string
}


variable "key_name" {
    description = "The name of the key pair to use for the EC2 instance"
    type        = string
}
variable "base_instance_count" {
    description = "The number of EC2 instances to launch"
    type        = number
}
variable "project_name" {
    description = "The name of the project"
    type        = string
}
variable "env" {
    description = "The environment for the EC2 instance"
    type        = string
}
variable "owner" {
    description = "The owner of the EC2 instance"
    type        = string
}