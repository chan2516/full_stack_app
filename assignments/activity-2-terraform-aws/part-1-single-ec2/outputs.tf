output "public_ip" { value = aws_instance.app.public_ip }
output "frontend_url" { value = "http://${aws_instance.app.public_ip}:3000" }
output "backend_url" { value = "http://${aws_instance.app.public_ip}:5000" }

