variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
variable "mongodb_uri" {
  type      = string
  sensitive = true
}
variable "backend_image_tag" {
  type    = string
  default = "latest"
}
variable "frontend_image_tag" {
  type    = string
  default = "latest"
}

