variable "container_name" {
  description = "Nombre del contenedor PHP + Apache"
  type        = string
  default     = "terraform-php-apache"
}

variable "image_name" {
  description = "Nombre de la imagen personalizada PHP + Apache"
  type        = string
}

variable "external_port" {
  description = "Puerto externo de Apache"
  type        = number
  default     = 8084
}

variable "phpmyadmin_port" {
  description = "Puerto externo de phpMyAdmin"
  type        = number
  default     = 8081
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "terraform_db"
}

variable "db_user" {
  description = "Usuario MySQL"
  type        = string
  default     = "terraform_user"
}

variable "db_password" {
  description = "Password del usuario MySQL"
  type        = string
  sensitive   = true
}

variable "db_root_password" {
  description = "Password root de MySQL"
  type        = string
  sensitive   = true
}

variable "container_path" {
  description = "Ruta donde MySQL almacena sus datos"
  type        = string
  default     = "/var/lib/mysql"
}