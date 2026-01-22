resource "local_file" "inventory" {
  filename = "${path.module}/inventory.ini"
  content  = <<-EOT
[web]
%{for idx, ip in var.public_ips~}
web${idx + 1} ansible_host=${ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/abdo/.ssh/id_rsa
%{endfor~}
EOT
}

resource "null_resource" "provision_ec2" {
  depends_on = [local_file.inventory]

  provisioner "local-exec" {
    command = "sleep 180 && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${path.module}/inventory.ini ${path.module}/playbook.yaml -f 1 -v"
  }
}