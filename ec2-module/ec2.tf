resource "aws_instance" "ec2_instance" {
    count = var.base_instance_count
    ami           = var.ami
    instance_type = var.instance_type
    subnet_id     = var.subnet_id
    vpc_security_group_ids = [var.security_group_id]
    key_name = var.key_name
    associate_public_ip_address = true


    tags = {
        Name = "${var.env}-ec2-instance-${count.index + 1}"
        Project = var.project_name
        Owner   = var.owner
    } 

#    lifecycle {
#        create_before_destroy = true
 #   }         
  
  depends_on = [ aws_key_pair.ec2_key ]
}


resource "aws_key_pair" "ec2_key" {
    key_name   = "terraform-key"
    public_key = file("/home/abdo/.ssh/id_rsa.pub")
}