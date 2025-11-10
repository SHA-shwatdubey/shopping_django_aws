terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state (S3 backend)
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "django-app/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Local to check if key pair should be created
locals {
  key_pair_name = "${var.project_name}-${var.environment}-key"
  # Set to true to create new resources, false to use existing
  create_resources = false
}

# Create key pair (will use existing if already created)
# Note: Set lifecycle ignore_changes to handle existing resources
resource "aws_key_pair" "django_app" {
  count      = local.create_resources ? 1 : 0
  key_name   = local.key_pair_name
  public_key = file(var.public_key_path)

  tags = {
    Name = "${var.project_name}-${var.environment}-keypair"
  }
}

# Data source to get existing key pair
data "aws_key_pair" "existing_or_new" {
  key_name = local.key_pair_name
  
  depends_on = [aws_key_pair.django_app]
}

# Security group for EC2 instance
resource "aws_security_group" "django_app" {
  count       = 1
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security group for Django application"
  vpc_id      = var.vpc_id

  # Allow SSH (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
    description = "SSH access"
  }

  # Allow HTTP (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # Allow HTTPS (port 443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-sg"
  }

  lifecycle {
    ignore_changes = all
  }
}

# EC2 instance for Django application
resource "aws_instance" "django_app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = data.aws_key_pair.existing_or_new.key_name

  vpc_security_group_ids = [aws_security_group.django_app[0].id]
  subnet_id              = var.subnet_id

  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  # User data for initial setup (update system packages)
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
  }))

  tags = {
    Name = "${var.project_name}-${var.environment}-instance"
  }

  monitoring = true

  depends_on = [aws_security_group.django_app[0]]
}

# Elastic IP for static public IP (optional)
resource "aws_eip" "django_app" {
  count             = var.use_elastic_ip ? 1 : 0
  instance          = aws_instance.django_app.id
  domain            = "vpc"
  public_ipv4_pool  = "amazon"
  depends_on        = [aws_instance.django_app]

  tags = {
    Name = "${var.project_name}-${var.environment}-eip"
  }
}

# Data source to fetch latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
