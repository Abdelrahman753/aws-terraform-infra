locals {

  security_group_name = "my_security_group"
  vpc_id              = module.imported_vpc.vpc_id

  allowed_ports = var.env == "production" ? var.allowed_ports_map["https"] : var.allowed_ports_map["http"]


  ingress_rules = [
    {
      from_port   = local.allowed_ports
      to_port     = local.allowed_ports
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  key_name = "terraform-key"



}


