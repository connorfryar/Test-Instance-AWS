output "AMI_Data" {
  value = data.aws_ami.Ubuntu["amd64"]
}

output "Instance_data" {
  value = data.aws_instance.TestInstanceInstanceData
}