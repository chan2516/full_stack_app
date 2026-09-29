data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = ["sg-0082b30babd96adad"]
  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    repository_url = var.github_repository_url
    mongodb_uri    = var.mongodb_uri
  })
  user_data_replace_on_change = true
  tags = { Name = "contact-app-single" }
}

