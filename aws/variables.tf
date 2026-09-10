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