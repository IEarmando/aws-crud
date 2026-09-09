terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================
# DEFAULT VPC
# ============================================================

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ============================================================
# AMAZON LINUX 2023
# ============================================================

data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ============================================================
# SECURITY GROUP
# ============================================================

resource "aws_security_group" "web" {
  name        = "${var.project_name}-sg"
  description = "Allow HTTP traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${var.project_name}-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# ============================================================
# EC2
# ============================================================

resource "aws_instance" "web" {
  ami           = data.aws_ssm_parameter.amazon_linux.value
  instance_type = var.instance_type

  subnet_id = sort(data.aws_subnets.default.ids)[0]

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  associate_public_ip_address = true

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash

    dnf update -y
    dnf install -y httpd

    systemctl enable httpd
    systemctl start httpd

    cat <<'HTML' > /var/www/html/index.html
    <!DOCTYPE html>
    <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Terraform AWS</title>
      </head>

      <body>
        <h1>Hola Mundo desde Terraform + AWS 🚀</h1>
        <p>EC2 desplegada automaticamente desde GitHub Actions.</p>
      </body>
    </html>
    HTML
  EOF

  tags = {
    Name        = var.project_name
    Environment = "pre"
    ManagedBy   = "Terraform"
  }
}