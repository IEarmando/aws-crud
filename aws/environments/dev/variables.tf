variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

# ============================================================
# EC2
# ============================================================

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.small"
}

# ============================================================
# PROJECT
# ============================================================

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "terraform-hello-aws"
}

variable "environment" {
  description = "Ambiente del despliegue (dev, pre, prod)"
  type        = string
  default     = "dev"
}

# ============================================================
# APPLICATION
# ============================================================

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

# ============================================================
# S3
# ============================================================

variable "state_bucket" {
  description = "Bucket S3 usado para el state y para dejar el release del CRUD"
  type        = string
  default     = "terraform-state-ec2-lab-141553305029-us-east-1-an"
}

# ============================================================
# VPC
# ============================================================

variable "vpc_cidr" {
  description = "Rango de direcciones IP de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ============================================================
# PUBLIC SUBNET
# ============================================================

variable "subnet_cidr" {
  description = "Rango de direcciones IP de la subred publica"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Zona de disponibilidad para la subred publica"
  type        = string
  default     = "us-east-1a"
}

# ============================================================
# PRIVATE SUBNET A
# ============================================================

variable "private_subnet_a_cidr" {
  description = "Rango de direcciones IP de la subred privada A"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_availability_zone_a" {
  description = "Zona de disponibilidad de la subred privada A"
  type        = string
  default     = "us-east-1a"
}

# ============================================================
# PRIVATE SUBNET B
# ============================================================

variable "private_subnet_b_cidr" {
  description = "Rango de direcciones IP de la subred privada B"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_availability_zone_b" {
  description = "Zona de disponibilidad de la subred privada B"
  type        = string
  default     = "us-east-1b"
}

# ============================================================
# RDS
# ============================================================

variable "db_instance_class" {
  description = "Tipo de instancia RDS MySQL"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Almacenamiento inicial de RDS en GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Nombre de la base de datos MySQL"
  type        = string
  default     = "terraform_db"
}

variable "db_username" {
  description = "Usuario administrador de RDS MySQL"
  type        = string
  default     = "terraform_user"
}

variable "db_password" {
  description = "Password del usuario administrador de RDS MySQL"
  type        = string
  sensitive   = true
}