output "alb_dns_name" {
  value = aws_lb.tftraining_alb.dns_name
}

output "website_url" {
  value = "http://${var.domain_name}"
}


output "wordpress_url" {
  value = aws_instance.tftraining_ec2_server.public_ip
}

output "database_endpoint" {
  value = aws_db_instance.tftraining_rds_instance.endpoint
}