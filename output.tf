output "public-ip" {
  value = aws_instance.Ec2Instance.public_ip
}

output "app_url" {
  description = "Tomcat app URL"
  value       = "http://${aws_instance.Ec2Instance.public_ip}:8080/student"
}