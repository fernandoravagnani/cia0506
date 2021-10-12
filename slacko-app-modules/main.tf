module "slackoapp" {
  source = "./modules/slacko-app"
  vpc_id = "vpc-0e963bfa8b8c37a47"
  subnet_cidr = "10.0.102.0/24"
  #name = Nome dos recursos criados na AWS, como um ponto adicional todo recurso criado pode ter um sufixo, como "nome_do_recursos_Sufixo": Exemplo: Slacko-ec2, Slacko-sg, slacko-route53
  nome_do_recurso_ec2_slacko = "slacko-app"
  nome_do_recurso_ec2_mongodb = "mongodb"
  tags_list = {
    "env" = "prod"
    "project" = "slack"
    "area" = "comercial"
    "cliente" = "empresa xpto"
  }
}

output "slackip" {
  value = module.slackoapp.slacko-app
}

output "mongoip" {
  value = module.slackoapp.slacko-mongodb
}
