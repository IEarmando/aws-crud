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
# VPC
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# ============================================================
# PUBLIC SUBNET
# ============================================================

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-${var.environment}-subnet"
  }
}

# ============================================================
# PRIVATE SUBNET A
# ============================================================

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = var.private_availability_zone_a
  tags = {
    Name = "${var.project_name}-${var.environment}-private-a"
  }
}

# ============================================================
# PRIVATE SUBNET B
# ============================================================

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = var.private_availability_zone_b
  tags = {
    Name = "${var.project_name}-${var.environment}-private-b"
  }
}

# ============================================================
# INTERNET GATEWAY
# ============================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# ============================================================
# PUBLIC ROUTE TABLE
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.project_name}-${var.environment}-rt"
  }
}

# ============================================================
# PUBLIC ROUTE TABLE ASSOCIATION
# ============================================================

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# PRIVATE ROUTE TABLE
# ============================================================
# La tabla solamente utiliza la ruta local de la VPC.
#
# EC2 -> RDS funciona mediante la red interna de la VPC.

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}

# ============================================================
# PRIVATE ROUTE TABLE ASSOCIATION - A
# ============================================================

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# ============================================================
# PRIVATE ROUTE TABLE ASSOCIATION - B
# ============================================================

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# ============================================================
# AMAZON LINUX 2023
# ============================================================

data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ============================================================
# SECURITY GROUP - WEB / EC2
# ============================================================

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Allow app + phpMyAdmin traffic"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.environment}-sg"
  }
}

# ============================================================
# EC2 - APP PORT
# ============================================================

resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.app_port
  to_port           = var.app_port
  ip_protocol       = "tcp"
}

# ============================================================
# EC2 - PHPMYADMIN PORT
# ============================================================

resource "aws_vpc_security_group_ingress_rule" "phpmyadmin" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.phpmyadmin_port
  to_port           = var.phpmyadmin_port
  ip_protocol       = "tcp"
}

# ============================================================
# EC2 - EGRESS
# ============================================================

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ============================================================
# SECURITY GROUP - RDS
# ============================================================

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Allow MySQL traffic from EC2 only"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

# ============================================================
# RDS - ALLOW MYSQL FROM EC2
# ============================================================
#
# NO usamos 0.0.0.0/0.
#
# Solamente las instancias que tengan el Security Group
# "web" podrán conectarse al RDS por TCP 3306.
#
# ============================================================

resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_ec2" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

# ============================================================
# RDS - EGRESS
# ============================================================

resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ============================================================
# IAM ROLE FOR EC2 + SYSTEMS MANAGER + S3
# ============================================================

resource "aws_iam_role" "ec2_ssm" {
  name = "${var.project_name}-${var.environment}-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ============================================================
# SSM MANAGED INSTANCE CORE
# ============================================================

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ============================================================
# S3 PERMISSION FOR EC2
#
# Allows EC2 to download the CRUD release from S3.
# ============================================================

resource "aws_iam_role_policy" "ec2_app_s3_read" {
  name = "${var.project_name}-${var.environment}-s3-app-read"
  role = aws_iam_role.ec2_ssm.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::terraform-state-ec2-lab-141553305029-us-east-1-an/app-releases/pre/*"
      }
    ]
  })
}

# ============================================================
# INSTANCE PROFILE
# ============================================================

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${var.project_name}-${var.environment}-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}

# ============================================================
# RDS SUBNET GROUP
# ============================================================

resource "aws_db_subnet_group" "mysql" {
  name = "${var.project_name}-${var.environment}-mysql"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-mysql-subnet-group"
  }
}

# ============================================================
# RDS MYSQL
# ============================================================

resource "aws_db_instance" "mysql" {
  identifier        = "${var.project_name}-${var.environment}-mysql"
  engine            = "mysql"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  port                 = 3306
  db_subnet_group_name = aws_db_subnet_group.mysql.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible        = false
  multi_az                   = false
  backup_retention_period    = 0
  deletion_protection        = false
  skip_final_snapshot        = true
  apply_immediately          = true
  auto_minor_version_upgrade = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-mysql"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Terraform AWS-Lab"
  }
}

# ============================================================
# EC2
# ============================================================

resource "aws_instance" "web" {
  ami           = data.aws_ssm_parameter.amazon_linux.value
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm.name

  depends_on = [
    aws_iam_role_policy_attachment.ssm_core,
    aws_iam_role_policy.ec2_app_s3_read
  ]

  user_data_replace_on_change = true

  user_data = <<-EOF
  #!/bin/bash
  set -e

  # ==========================================
  # APPLICATION DIRECTORY
  # ==========================================
  mkdir -p /opt/app
  chown ec2-user:ec2-user /opt/app

  # ==========================================
  # UPDATE SYSTEM
  # ==========================================
  dnf update -y

  # ==========================================
  # DOCKER
  # ==========================================
  dnf install -y docker

  systemctl enable docker
  systemctl start docker

  usermod -aG docker ec2-user

  # ==========================================
  # DOCKER COMPOSE
  # ==========================================
  mkdir -p /usr/local/lib/docker/cli-plugins

  curl -fSL \
    https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o /usr/local/lib/docker/cli-plugins/docker-compose

  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

  # ==========================================
  # DOCKER BUILDX
  # ==========================================
  BUILDX_VERSION="v0.13.1"

  curl -fSL \
    "https://github.com/docker/buildx/releases/download/$${BUILDX_VERSION}/buildx-$${BUILDX_VERSION}.linux-amd64" \
    -o /usr/local/lib/docker/cli-plugins/docker-buildx

  chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

  # ==========================================
  # VERIFY INSTALLATION
  # ==========================================
  docker --version
  docker compose version
  docker buildx version

  # ==========================================
  # BOOTSTRAP COMPLETE
  # ==========================================
  touch /opt/app/.instance-ready

EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Terraform AWS-Lab"
  }
}