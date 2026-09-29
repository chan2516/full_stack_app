output "backend_ecr_url" { value = aws_ecr_repository.backend.repository_url }
output "frontend_ecr_url" { value = aws_ecr_repository.frontend.repository_url }
output "ecs_cluster_name" { value = aws_ecs_cluster.main.name }
output "vpc_id" { value = aws_vpc.main.id }
output "alb_url" { value = "http://${aws_lb.main.dns_name}" }

