###################### AMI Lookup ######################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
# example at ./Resource \notes/aws_ami_example.txt
data "aws_ami" "Ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

###################### Instance Definition ######################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
# example at /Resource \notes/aws_instance_example.txt
resource "aws_instance" "TestInstanceInstance" {
  subnet_id                   = aws_subnet.mainSubnet.id
  ami                         = data.aws_ami.Ubuntu.id
  instance_type               = var.InstanceType
  security_groups             = [aws_security_group.TestInstanceSG.id]
  associate_public_ip_address = true
  availability_zone           = "us-east-1a"

  user_data_replace_on_change = true
  user_data                   = file("${path.module}/userdata.sh")
  root_block_device {
    volume_size = var.EBSSize
    volume_type = var.EBSType
  }

  tags = {
    Name = random_pet.pet.id
    # Possible to do ebs attachment here
    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#tag-guide
  }
}

######################### DATA LOOKUPS #########################
data "aws_instance" "TestInstanceInstanceData" {
  #instance_id = "i-097d63708ebb770e2"
  # TODO replace with instance that is being built in this script.
  instance_id = aws_instance.TestInstanceInstance.id
}

