variable "vpc_id" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "tags_list" {
  type = map
}

variable "nome_do_recurso_ec2_jenkins" {
  type = string
}

variable "instance_type_ec2_jenkins" {
  type = string
}
