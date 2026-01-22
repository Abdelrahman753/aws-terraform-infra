resource "aws_vpc" "imported_vpc" {
    cidr_block = var.cidr_block

  tags = {
    Name        = var.project_name
    Environment = var.env
  }
#  lifecycle {
#    prevent_destroy = true
#  }
 

}