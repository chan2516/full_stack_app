variable "aws_region" { type = string
default = "ap-south-1" }
variable "instance_type" { type = string
default = "t3.micro" }
variable "key_name" { type = string }
variable "allowed_ssh_cidr" { type = string }
variable "github_repository_url" { type = string }
variable "mongodb_uri" { type = string
sensitive = true }

