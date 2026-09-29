data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_ecr_repository" "backend" {
  name = "contact-app-backend"
  image_scanning_configuration {
    scan_on_push = true
  }
}
resource "aws_ecr_repository" "frontend" {
  name = "contact-app-frontend"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "contact-ecs-vpc"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "contact-public-${count.index + 1
    }"
  }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name_prefix = "contact-alb-"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "ecs" {
  name_prefix = "contact-ecs-"
  vpc_id      = aws_vpc.main.id
  ingress {
    description     = "Express from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    description     = "Flask from ALB"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    description = "Flask between ECS tasks"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "main" {
  name               = "contact-app-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}
resource "aws_lb_target_group" "frontend" {
  name        = "contact-frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
  health_check {
    path    = "/health"
    matcher = "200"
  }
}
resource "aws_lb_target_group" "backend" {
  name        = "contact-backend-tg"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
  health_check {
    path    = "/health"
    matcher = "200"
  }
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  condition {
    path_pattern {
      values = ["/api", "/api/*"]
    }
  }
}

resource "aws_ecs_cluster" "main" {
  name = "contact-app-cluster"
}
resource "aws_iam_role" "execution" {
  name = "contact-app-ecs-execution"
  assume_role_policy = jsonencode({
    Version = "2012-10-17", Statement = [{
      Effect = "Allow", Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }, Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/contact-backend"
  retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/contact-frontend"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "contact-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  container_definitions = jsonencode([{
    name = "backend", image = "${aws_ecr_repository.backend.repository_url
      }:${var.backend_image_tag
      }", essential = true, portMappings = [{
        containerPort = 5000, protocol = "tcp"
        }], environment = [{
        name = "MONGODB_URI", value = var.mongodb_uri
        }, {
        name = "MONGODB_DATABASE", value = "first_project"
        }, {
        name = "MONGODB_COLLECTION", value = "submissions"
        }, {
        name = "CORS_ORIGINS", value = "*"
      }], logConfiguration = {
      logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.backend.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}
resource "aws_ecs_task_definition" "frontend" {
  family                   = "contact-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  container_definitions = jsonencode([{
    name = "frontend", image = "${aws_ecr_repository.frontend.repository_url
      }:${var.frontend_image_tag
      }", essential = true, portMappings = [{
        containerPort = 3000, protocol = "tcp"
        }], environment = [{
        name = "PORT", value = "3000"
        }, {
        name = "BACKEND_URL", value = "http://backend.contact.local:5000"
      }], logConfiguration = {
      logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.frontend.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_service_discovery_private_dns_namespace" "main" {
  name = "contact.local"
  vpc  = aws_vpc.main.id
}
resource "aws_service_discovery_service" "backend" {
  name = "backend"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}
resource "aws_ecs_service" "backend" {
  name            = "contact-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 5000
  }
  service_registries {
    registry_arn = aws_service_discovery_service.backend.arn
  }
  depends_on = [aws_lb_listener_rule.api]
}
resource "aws_ecs_service" "frontend" {
  name            = "contact-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 3000
  }
  depends_on = [aws_lb_listener.http, aws_ecs_service.backend]
}

