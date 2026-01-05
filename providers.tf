terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  # availability_zone = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
provider "random" {
}