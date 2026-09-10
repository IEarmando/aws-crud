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

# DEFAULT VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# AMAZON LINUX 2023
data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# SECURITY GROUP
resource "aws_security_group" "web" {
  name        = "${var.project_name}-sg"
  description = "Allow app + phpMyAdmin traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${var.project_name}-sg"
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
# IAM ROLE FOR EC2 + SYSTEMS MANAGER + S3 (para bajar el release del CRUD)
# ============================================================
resource "aws_iam_role" "ec2_ssm" {
  name = "${var.project_name}-ssm-role"

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

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "s3_app_release" {
  name = "${var.project_name}-s3-app-release"
  role = aws_iam_role.ec2_ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.state_bucket}/app-releases/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${var.project_name}-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}

# ============================================================
# PERMISO PARA QUE EL RUNNER DE GITHUB ACTIONS PUEDA SUBIR EL ZIP
# ============================================================
resource "aws_iam_user_policy" "github_actions_s3_upload" {
  name = "${var.project_name}-github-s3-upload"
  user = "terraform-github-lab"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "arn:aws:s3:::${var.state_bucket}/app-releases/*"
      }
    ]
  })
}

# EC2
resource "aws_instance" "web" {
  ami           = data.aws_ssm_parameter.amazon_linux.value
  instance_type = var.instance_type

  subnet_id = sort(data.aws_subnets.default.ids)[0]

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm.name

  depends_on = [
    aws_iam_role_policy_attachment.ssm_core
  ]

  user_data_replace_on_change = true
  user_data                   = <<-EOF
    #!/bin/bash
    dnf update -y

    dnf install -y docker
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user

    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    mkdir -p /opt/app
    chown ec2-user:ec2-user /opt/app
  EOF

  tags = {
    Name        = var.project_name
    Environment = "pre"
    ManagedBy   = "Terraform"
    Project     = "Terraform AWS-Lab"
  }
}