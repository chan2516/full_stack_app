data "aws_vpc" "default" { default = true }
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter { name = "name"
values = ["al2023-ami-2023.*-x86_64"] }
  filter { name = "virtualization-type"
values = ["hvm"] }
}

resource "aws_security_group" "app" {
  name_prefix = "contact-single-"
  vpc_id      = data.aws_vpc.default.id
  ingress { description = "SSH"
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = [var.allowed_ssh_cidr] }
  ingress { description = "Express"
from_port = 3000
to_port = 3000
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"] }
  ingress { description = "Flask evidence"
from_port = 5000
to_port = 5000
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"] }
  egress { from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app.id]
  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    repository_url = var.github_repository_url
    mongodb_uri     = var.mongodb_uri
  })
  user_data_replace_on_change = true
  tags = { Name = "contact-app-single" }
}

