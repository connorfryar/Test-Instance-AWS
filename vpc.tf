###################### VPC Definition ######################

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

###################### Subnet Definition ######################

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "mainSubnet" {
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  cidr_block              = "10.0.10.0/24"
  availability_zone       = var.availability_zone
}

###################### Internet Gateway Definition ######################

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

###################### Route Table Definition ######################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

###################### Route Table Attachment ######################

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.mainSubnet.id
  route_table_id = aws_route_table.public.id
}
