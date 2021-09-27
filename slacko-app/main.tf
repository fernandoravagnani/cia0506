data "aws_ami" "slacko-app" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["Amazon*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_subnet" "subnet_public" {
  cidr_block = "10.0.102.0/24"
}

# ssh-keygen -C slacko -f slacko
resource "aws_key_pair" "slacko-sshkey" {
  key_name   = "slacko-app-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCknVl7SQjtlma6rnOc/rgWt+nqmA6ZE5ugYFcxM8DnHYpF8evcklTNcBb7enTNhg3jJlDZfwN5Pj6ZVTMm+MWr8NoyMWNFkRPgiapw5pFnfWIvzFAJuN8fw8Px+DwEGqftXgxdq61KagNqGIdK46LjXjWpEoQr2C4KutRxx2QJK2cLjRWEcri/O20tnTiONfR7WyMGIB75FY5x4XQbng0DnnzQtlW41JSaima0DbfKwTF2JAbcajJb/zVQn1n1jXqLwOQzxZjrjQtZG5xEeTu66RU3bssz7x05PW60M0xveC29vNSjZjwG8IFob0qn4PCNmjOBa4fhSFCsw4CbV0Szn8OYPgjjm8u/cPRlf53BuTfsd2Jr+MmXhQA44tg9JSadmT8r6RxPaYDdGuB6M5Y9EYTbAVMgh/dYHxajKT8O7ouQNMyiFwC0fzS1C4sBEpQKsGT718HmlDs6KWMn9tU8zF08PGA76UPTlR6NTpk/QU1HhWoZZv5Fu7d7KwRcZpE= slacko"
}

resource "aws_instance" "slacko-app" {
  ami = data.aws_ami.slacko-app.id
  instance_type = "t2.micro"
  subnet_id = data.aws_subnet.subnet_public.id
  associate_public_ip_address = true

  tags = {
    Name = "slacko-app"
  }

  key_name = aws_key_pair.slacko-sshkey.id
  user_data = file("ec2.sh")
}

resource "aws_instance" "mongodb" {
  ami = data.aws_ami.slacko-app.id
  instance_type = "t2.micro"
  subnet_id = data.aws_subnet.subnet_public.id

  tags = {
    Name = "mongodb"
  }

  key_name = aws_key_pair.slacko-sshkey.id
  user_data = file("mongodb.sh")

}

resource "aws_security_group" "allow-slacko" {
  name = "allow_ssh_http"
  description = "Allow ssh and http port"
  vpc_id = "vpc-03311efd294df79be"

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
      description = "Allow Http"
      from_port = 80
      to_port = 80
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
    Name = "allow_ssh_http"
  }
}

resource "aws_security_group" "allow-mongodb" {
  name = "allow_mongodb"
  description = "Allow MongoDB"
  vpc_id = "vpc-03311efd294df79be"

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
      description = "Allow MongoDB"
      from_port = 27017
      to_port = 27017
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
    Name = "allow_mongodb"
  }
}

resource "aws_network_interface_sg_attachment" "mongodb-sg" {
  security_group_id = aws_security_group.allow-mongodb.id
  network_interface_id = aws_instance.mongodb.primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "slacko-sg" {
  security_group_id = aws_security_group.allow-slacko.id
  network_interface_id = aws_instance.slacko-app.primary_network_interface_id
}

resource "aws_route53_zone" "slacko_zone" {
  name = "iaac0506.com.br"

  vpc {
    vpc_id = "vpc-03311efd294df79be"
  }
}

resource "aws_route53_record" "mongodb" {
  zone_id = aws_route53_zone.slacko_zone.id
  name    = "mongodb.iaac0506.com.br"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.mongodb.private_ip]
}
