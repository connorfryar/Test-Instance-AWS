###################### EC2 Instance ######################
variable "InstanceName" {
  type        = string
  description = "Name of the test bench instance"
  default = "depricated"
}

variable "InstanceType" {
  type        = string
  description = "Instance type of test bench. Recommended 2vCPU and 8GiB ram -- t3.medium"
  default     = "t3.medium"
}

###################### EBS ######################

variable "EBSSize" {
  type        = number
  description = "The size of the Storage Volume. Must be less that 100GiB"

  validation {
    condition     = var.EBSSize < 100
    error_message = "test bench volume must be less than 100 GiB."
  }
}

variable "EBSType" {
  type        = string
  description = "Type of test bench EBS i.e. gp2, gp3, io1, io2"
  default     = "gp3"
}

# Route53 variables
variable "subdomain" {
  type        = string
  description = "Subdomain name for Route53"
}
variable "yourname" {
  type        = string
  description = "Your name for Route53"
  default     = "connor-fryar"
}
variable "domain" {
  type        = string
  description = "Domain zone for Route53"
  default     = "sbx.hashidemos.io"

}

locals {
  domain_name = "${var.subdomain}.${var.yourname}.${var.domain}"
}

variable "availability_zone" {
  type        = string
  description = "availability zone"
  default     = "us-east-1a"
}

