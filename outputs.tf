output "domain_name" {
  description = "Instance name"
  value       = var.InstanceName
}

output "public_ip_address" {
  description = "Instance public IP"
  value       = aws_instance.TestInstanceInstance.public_ip

}