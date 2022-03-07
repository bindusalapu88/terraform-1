data "aws_vpc" "default_vpc"{
    default = true
}
data "aws_subnet" "first"{
    vpc_id = data.aws_vpc.default_vpc.id
    cidr_block = "172.31.16.0/20"
}
data "aws_security_group" "open_all"{
    vpc_id = data.aws_vpc.default_vpc.id
    name = "ansibleopenall"
}
resource "aws_instance" "web_instance_1" {
  count = terraform.workspace == "UAT"?2:1
  ami = "ami-0892d3c7ee96c0bf7"
  associate_public_ip_address = true
  instance_type = "t2.micro"
  key_name = "cicd"
  vpc_security_group_ids = [data.aws_security_group.open_all.id]
  subnet_id = data.aws_subnet.first.id

  tags = {
    Name = "Web"
  }
}
resource "null_resource" "deployapp" {
  triggers = {
    build_id = var.build_id
  }
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("./cicd.pem")
    host = aws_instance.web_instance_1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install apache2 -y "
    ]
  }
    
  provisioner "local_exec" {
    command = "ANSIBLE_HOST_KEY _CHECKING=FALSE ansible-playbook -u ubuntu -i '${aws_instance.web_instance_1.public_ip}','--private_key','./cicd.pem' sample.yaml"
  }
  depends_on = [
    aws_instance.web_instance_1
  ]  
}
   


