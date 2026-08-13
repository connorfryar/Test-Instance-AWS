###################### Instance outputs ######################

output "public_ip_address" {
  description = "Instance public IP"
  value       = aws_instance.TestInstanceInstance.public_ip

}

###################### Route53 outputs ######################

output "route53_zone" {
  value = data.aws_route53_zone.hashidemos
}