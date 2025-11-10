variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "shoppinglyx"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "vpc_id" {
  description = "VPC ID for resources (default VPC if not specified)"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID for EC2 instance (optional, uses default VPC subnet if not specified)"
  type        = string
  default     = null
}

variable "public_key_path" {
  description = "Path to public key file for EC2 key pair"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change to restrict SSH access
}

variable "use_elastic_ip" {
  description = "Whether to create and associate an Elastic IP"
  type        = bool
  default     = true
}
