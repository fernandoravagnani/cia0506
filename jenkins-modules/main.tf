module "jenkins" {
  source = "./modules/jenkins"
  vpc_id = "vpc-0e963bfa8b8c37a47"
  subnet_cidr = "10.0.102.0/24"
  nome_do_recurso_ec2_jenkins = "jenkins"
  instance_type_ec2_jenkins = "t2.micro"
  tags_list = {
    "env" = "prod"
    "project" = "jenkins"
    "area" = "infraestrutura"
    "cliente" = "empresa xpto"
  }
}

output "jenkinsip" {
  value = module.jenkins.jenkinsip
}
