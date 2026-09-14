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

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

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

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
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
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Allow app + phpMyAdmin traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.app_port
  to_port           = var.app_port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "phpmyadmin" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.phpmyadmin_port
  to_port           = var.phpmyadmin_port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id
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
# Allows EC2 to download the CRUD release from S3
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
# EC2
# ============================================================

resource "aws_instance" "web" {
  ami           = data.aws_ssm_parameter.amazon_linux.value
  instance_type = var.instance_type

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name

  depends_on = [
    aws_iam_role_policy_attachment.ssm_core,
    aws_iam_role_policy.ec2_app_s3_read
  ]

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash

    set -e

    dnf update -y

    dnf install -y docker

    systemctl enable docker
    systemctl start docker

    usermod -aG docker ec2-user

    # Docker Compose
    mkdir -p /usr/local/lib/docker/cli-plugins

    curl -fSL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
      -o /usr/local/lib/docker/cli-plugins/docker-compose

    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    # Docker Buildx
    BUILDX_VERSION=$(curl -fsSL https://api.github.com/repos/docker/buildx/releases/latest | grep '"tag_name"' | cut -d '"' -f4)

    curl -fSL "https://github.com/docker/buildx/releases/download/$${BUILDX_VERSION}/buildx-$${BUILDX_VERSION}.linux-amd64" \
      -o /usr/local/lib/docker/cli-plugins/docker-buildx

    chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

    # Application directory
    mkdir -p /opt/app

    chown ec2-user:ec2-user /opt/app
  EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Terraform AWS-Lab"
  }
}