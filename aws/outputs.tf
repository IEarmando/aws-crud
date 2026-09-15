output "instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "IP publica de la instancia"
  value       = aws_instance.web.public_ip
}

output "website_url" {
  description = "URL publica del CRUD"
  value       = "http://${aws_instance.web.public_ip}:${var.app_port}"
}

output "phpmyadmin_url" {
  description = "URL publica de phpMyAdmin"
  value       = "http://${aws_instance.web.public_ip}:${var.phpmyadmin_port}"
}

# ============================================================
# RDS OUTPUTS
# ============================================================

output "rds_endpoint" {
  description = "Endpoint DNS de RDS MySQL"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "Puerto de RDS MySQL"
  value       = aws_db_instance.mysql.port
}

output "rds_database" {
  description = "Nombre de la base de datos RDS"
  value       = aws_db_instance.mysql.db_name
}

output "rds_username" {
  description = "Usuario de RDS MySQL"
  value       = aws_db_instance.mysql.username
  sensitive   = true

}