variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.small"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "terraform-hello-aws"
}

variable "app_port" {
  description = "Puerto externo del contenedor PHP/Apache (CRUD)"
  type        = number
  default     = 8082
}

variable "phpmyadmin_port" {
  description = "Puerto externo de phpMyAdmin"
  type        = number
  default     = 8081
}

variable "state_bucket" {
  description = "Bucket S3 usado para el state y para dejar el release del CRUD"
  type        = string
  default     = "terraform-state-ec2-lab-141553305029-us-east-1-an"
}