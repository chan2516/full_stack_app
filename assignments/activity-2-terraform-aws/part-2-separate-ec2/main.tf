data "aws_availability_zones" "available" { state = "available" }
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter { name = "name"
values = ["al2023-ami-2023.*-x86_64"] }
  filter { name = "virtualization-type"
values = ["hvm"] }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "contact-app-vpc" }
}
resource "aws_internet_gateway" "main" { vpc_id = aws_vpc.main.id }
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "contact-public" }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.main.id }
}
resource "aws_route_table_association" "public" { subnet_id = aws_subnet.public.id
route_table_id = aws_route_table.public.id }

resource "aws_security_group" "frontend" {
  name_prefix = "contact-frontend-"
  vpc_id      = aws_vpc.main.id
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
  egress { from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_security_group" "backend" {
  name_prefix = "contact-backend-"
  vpc_id      = aws_vpc.main.id
  ingress { description = "SSH"
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = [var.allowed_ssh_cidr] }
  ingress { description = "Flask from frontend"
from_port = 5000
to_port = 5000
protocol = "tcp"
security_groups = [aws_security_group.frontend.id] }
  ingress { description = "Flask public assignment access"
from_port = 5000
to_port = 5000
protocol = "tcp"
cidr_blocks = [var.public_app_cidr] }
  egress { from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_instance" "backend" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.backend.id]
  user_data = templatefile("${path.module}/backend-user-data.sh.tftpl", {
    repository_url = var.github_repository_url
    mongodb_uri     = var.mongodb_uri
  })
  user_data_replace_on_change = true
  tags = { Name = "contact-backend" }
}

resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.frontend.id]
  user_data = templatefile("${path.module}/frontend-user-data.sh.tftpl", {
    repository_url = var.github_repository_url
    backend_ip     = aws_instance.backend.private_ip
  })
  user_data_replace_on_change = true
  tags = { Name = "contact-frontend" }
}

