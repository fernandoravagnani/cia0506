data "aws_ami" "jenkins-ami" {
  most_recent = true
  # Canonical - Ubuntu
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_subnet" "subnet_public" {
  cidr_block = var.subnet_cidr
}

# ssh-keygen -C slacko -f slacko
resource "aws_key_pair" "slacko-sshkey" {
  key_name   = "slacko-app-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCknVl7SQjtlma6rnOc/rgWt+nqmA6ZE5ugYFcxM8DnHYpF8evcklTNcBb7enTNhg3jJlDZfwN5Pj6ZVTMm+MWr8NoyMWNFkRPgiapw5pFnfWIvzFAJuN8fw8Px+DwEGqftXgxdq61KagNqGIdK46LjXjWpEoQr2C4KutRxx2QJK2cLjRWEcri/O20tnTiONfR7WyMGIB75FY5x4XQbng0DnnzQtlW41JSaima0DbfKwTF2JAbcajJb/zVQn1n1jXqLwOQzxZjrjQtZG5xEeTu66RU3bssz7x05PW60M0xveC29vNSjZjwG8IFob0qn4PCNmjOBa4fhSFCsw4CbV0Szn8OYPgjjm8u/cPRlf53BuTfsd2Jr+MmXhQA44tg9JSadmT8r6RxPaYDdGuB6M5Y9EYTbAVMgh/dYHxajKT8O7ouQNMyiFwC0fzS1C4sBEpQKsGT718HmlDs6KWMn9tU8zF08PGA76UPTlR6NTpk/QU1HhWoZZv5Fu7d7KwRcZpE= slacko"
}

resource "aws_instance" "jenkins-ec2" {
  ami = data.aws_ami.jenkins-ami.id
  instance_type = var.instance_type_ec2_jenkins
  subnet_id = data.aws_subnet.subnet_public.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow-jenkins.id]

  tags = {
    Name = var.nome_do_recurso_ec2_jenkins
    Env = var.tags_list["env"]
    Project = var.tags_list["project"]
    Area = var.tags_list["area"]
    Cliente = var.tags_list["cliente"]
  }

  key_name = aws_key_pair.slacko-sshkey.id

  #user_data = file("${path.module}/files/jenkins.sh")

  provisioner "file" {
    source      = "${path.module}/files/jenkins.sh"
    destination = "/tmp/jenkins.sh"
  }

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ubuntu"
    private_key="${file("${path.module}/slacko")}"
    timeout = "3m"
  } 

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/jenkins.sh",
      "sudo /tmp/jenkins.sh",
      "sudo cat /var/lib/jenkins/secrets/initialAdminPassword",
    ]
  }

  depends_on = [
    aws_security_group.allow-jenkins,
  ]
}

resource "aws_security_group" "allow-jenkins" {
  name = "allow_ssh_jenkins"
  description = "Allow ssh and jenkins port"
  vpc_id = var.vpc_id

  ingress = [
    {
      description = "Allow SSH"
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids = null
      security_groups = null
      self = null
    },
    {
      description = "Allow Jenkins Port"
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]  

  egress = [
    {
      description = "allow all"
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]

  tags = {
    Name = "allow_ssh_jenkins"
  }
}

#resource "aws_network_interface_sg_attachment" "jenkins-sg" {
#  security_group_id = aws_security_group.allow-jenkins.id
#  network_interface_id = aws_instance.jenkins-ec2.primary_network_interface_id
#}

resource "aws_route53_zone" "slacko_zone" {
  name = "iaac0506.com.br"

  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "jenkins" {
  zone_id = aws_route53_zone.slacko_zone.id
  name    = "jenkins.iaac0506.com.br"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.jenkins-ec2.private_ip]
}
