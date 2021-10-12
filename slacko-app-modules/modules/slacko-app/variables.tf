variable "vpc_id" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "tags_list" {
  type = map
}

variable "nome_do_recurso_ec2_slacko" {
  type = string
}

variable "nome_do_recurso_ec2_mongodb" {
  type = string
}
