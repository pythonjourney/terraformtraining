output "alb_dns_name" {
  value = aws_lb.tftraining_alb.dns_name
}

output "website_url" {
  value = "http://${var.domain_name}"
}