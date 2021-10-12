output "jenkinsip" {
  value = aws_instance.jenkins-ec2.public_ip
}
