output "vpc1_instance_public_ip" {
  value = aws_instance.vpc1_instance.public_ip
}

output "vpc2_instance_public_ip" {
  value = aws_instance.vpc2_instance.public_ip
}