# Terraform configuration for Nagios Monitoring Server
# This creates a separate EC2 instance for running Nagios Core

# Generate unique suffix for security group names to avoid conflicts
locals {
  sg_suffix = substr(replace(timestamp(), "/[:-]/", ""), 0, 8)
}

# Security group for Nagios monitoring server
resource "aws_security_group" "nagios_server" {
  name        = "${var.project_name}-${var.environment}-nagios-sg-${local.sg_suffix}"
  description = "Security group for Nagios monitoring server"
  vpc_id      = var.vpc_id

  # Allow SSH (port 22) from allowed CIDR blocks
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
    description = "SSH access to Nagios server"
  }

  # Allow Nagios Web UI (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Nagios Web UI HTTP"
  }

  # Allow Nagios Web UI HTTPS (port 443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Nagios Web UI HTTPS"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-nagios-sg"
  }
}

# Security group for NRPE clients (attached to Django app instance)
resource "aws_security_group" "nagios_nrpe" {
  name        = "${var.project_name}-${var.environment}-nagios-nrpe-sg-${local.sg_suffix}"
  description = "Security group for Nagios NRPE clients"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-nagios-nrpe-sg"
  }
}

# Allow Nagios server to receive connections FROM NRPE agents (for some plugins)
resource "aws_security_group_rule" "nagios_server_nrpe_ingress" {
  type                     = "ingress"
  from_port                = 5666
  to_port                  = 5666
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nagios_nrpe.id
  security_group_id        = aws_security_group.nagios_server.id
  description              = "NRPE agents can contact Nagios server"
}

# Allow NRPE agents to receive NRPE check queries from Nagios server
resource "aws_security_group_rule" "nrpe_from_nagios_server" {
  type                     = "ingress"
  from_port                = 5666
  to_port                  = 5666
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nagios_server.id
  security_group_id        = aws_security_group.nagios_nrpe.id
  description              = "Allow Nagios server to query NRPE agents"
}

# EC2 instance for Nagios monitoring server
resource "aws_instance" "nagios_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.nagios_instance_type
  key_name               = data.aws_key_pair.existing_or_new.key_name
  vpc_security_group_ids = [aws_security_group.nagios_server.id]
  subnet_id              = var.subnet_id

  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.nagios_root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  # User data for initial setup
  user_data = base64encode(templatefile("${path.module}/nagios_user_data.sh", {
    project_name = var.project_name
  }))

  tags = {
    Name = "${var.project_name}-${var.environment}-nagios-server"
  }

  monitoring = true

  depends_on = [
    aws_security_group.nagios_server,
    aws_security_group.nagios_nrpe
  ]
}

# Add NRPE security group to existing Django app instance
resource "aws_security_group_rule" "django_nrpe_ingress" {
  type                     = "ingress"
  from_port                = 5666
  to_port                  = 5666
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nagios_server.id
  security_group_id        = length(aws_security_group.django_app) > 0 ? aws_security_group.django_app[0].id : data.aws_security_groups.existing_sg.ids[0]
  description              = "NRPE from Nagios server"
}

# Elastic IP for Nagios server (removed - use public IP directly)
# resource "aws_eip" "nagios_server" {
#   instance   = aws_instance.nagios_server.id
#   domain     = "vpc"
#   depends_on = [aws_instance.nagios_server]
# 
#   tags = {
#     Name = "${var.project_name}-${var.environment}-nagios-eip"
#   }
# }

# Outputs for Nagios server
output "nagios_server_public_ip" {
  description = "Public IP address of Nagios monitoring server"
  value       = aws_instance.nagios_server.public_ip
}

output "nagios_server_private_ip" {
  description = "Private IP address of Nagios monitoring server"
  value       = aws_instance.nagios_server.private_ip
}

output "nagios_server_instance_id" {
  description = "Instance ID of Nagios monitoring server"
  value       = aws_instance.nagios_server.id
}

output "nagios_web_url" {
  description = "URL to access Nagios web dashboard"
  value       = "http://${aws_instance.nagios_server.public_ip}/nagios"
}

output "django_app_private_ip" {
  description = "Private IP address of Django application server"
  value       = aws_instance.django_app.private_ip
}

output "nagios_nrpe_sg_id" {
  description = "Security group ID for NRPE clients"
  value       = aws_security_group.nagios_nrpe.id
}
