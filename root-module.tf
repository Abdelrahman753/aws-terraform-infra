module "imported_vpc" {
  source       = "./vpc_module"
  cidr_block   = var.cidr_block
  project_name = var.vpc_name
  env          = var.env
}

module "subnet_module" {
  source       = "./subnet_module"
  subnet_cider = var.subnet_cidr
  vpc_id       = module.imported_vpc.vpc_id
  region       = var.region
}

module "ec2" {
  source              = "./ec2-module"
  base_instance_count = var.base_instance_count
  ami                 = data.aws_ami.ubuntu.id
  instance_type       = var.instance_type
  subnet_id           = module.subnet_module.subnet_id
  security_group_id   = module.security_group.security_group_id
  key_name            = local.key_name
  project_name        = var.project_name
  env                 = var.env
  owner               = var.owner
  depends_on          = [module.subnet_module, module.security_group]


}


module "security_group" {
  source        = "./security_group"
  Security-name = local.security_group_name
  vpc_id        = local.vpc_id
  ingress_rules = local.ingress_rules
  egress_rules  = local.egress_rules
  env           = var.env
  depends_on    = [module.imported_vpc]

}

module "ansible" {
  source = "./ansible"
  public_ips          = module.ec2.ec2-ip
  depends_on          = [module.ec2]
}

module "igw" {
  source = "./IGW"

  vpc_id = module.imported_vpc.vpc_id
  name   = "lab3-igw"

}

module "public_route_table" {
  source = "./route_table"

  vpc_id     = module.imported_vpc.vpc_id
  name       = "public-rt"

  routes = [
    {
      cidr_block = "0.0.0.0/0"
      gateway_id = module.igw.igw_id
    }
  ]

  subnet_ids = [
    module.subnet_module.subnet_id
  ]
}
