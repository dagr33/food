terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for resources"
  type        = string
}

variable "allow_ssh_cidr" {
  description = "CIDR block allowed to SSH"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for EC2"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

provider "aws" {
  region = var.aws_region
}

# --- ECR Repository ---
resource "aws_ecr_repository" "app" {
  name                 = "${var.project}-repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
}

# --- IAM role instance profile to pull from ECR ---
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service" identifiers = ["ec2.amazonaws.com"] }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${var.project}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Allow ECR pull + CloudWatch logs (optional)
data "aws_iam_policy_document" "ecr_pull" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_pull" {
  name   = "${var.project}-ecr-pull"
  policy = data.aws_iam_policy_document.ecr_pull.json
}

resource "aws_iam_role_policy_attachment" "attach_ecr_pull" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ecr_pull.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# --- Security Group (22,80,443) ---
resource "aws_security_group" "web_sg" {
  name        = "${var.project}-sg"
  description = "Allow SSH/HTTP/HTTPS"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allow_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- EC2 ---
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"] # Amazon
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  tags = { Name = "${var.project}-ec2" }

  # Թեթեւ նախապատրաստում Ansible-ի համար
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y python3 git
              # enable ssh keepalive
              echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
              systemctl restart sshd
              EOF
}

output "ecr_repo_url" {
  value = aws_ecr_repository.app.repository_url
}
output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}
