#!/bin/bash
set -e

# Quick Setup Script for Django AWS Deployment
# This script helps you set up all necessary configurations for deployment

echo "=========================================="
echo "Django AWS Deployment - Setup Assistant"
echo "=========================================="
echo ""

# Check if required tools are installed
echo "Checking required tools..."

command -v aws &> /dev/null || { echo "AWS CLI is required but not installed. Please install it first."; exit 1; }
command -v terraform &> /dev/null || { echo "Terraform is required but not installed. Please install it first."; exit 1; }
command -v ansible &> /dev/null || { echo "Ansible is required but not installed. Please install it first."; exit 1; }

echo "✓ All required tools found"
echo ""

# Check if SSH key exists
echo "Checking SSH key setup..."

if [ ! -f ~/.ssh/django-app-key ]; then
    echo "SSH key not found. Creating new key pair..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/django-app-key -N ""
    echo "✓ SSH key pair created at ~/.ssh/django-app-key"
else
    echo "✓ SSH key already exists"
fi
echo ""

# Get current user's IP
echo "Getting your IP address..."
MY_IP=$(curl -s https://checkip.amazonaws.com | tr -d '\n')
echo "Your IP: $MY_IP"
echo ""

# Create terraform.tfvars
echo "Creating Terraform variables file..."
if [ ! -f terraform/terraform.tfvars ]; then
    cp terraform/terraform.tfvars.example terraform/terraform.tfvars
    
    # Update IP in tfvars (basic sed)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/YOUR_IP_ADDRESS/$MY_IP/g" terraform/terraform.tfvars
    else
        sed -i "s/YOUR_IP_ADDRESS/$MY_IP/g" terraform/terraform.tfvars
    fi
    
    echo "✓ terraform/terraform.tfvars created with your IP"
else
    echo "✓ terraform/terraform.tfvars already exists"
fi
echo ""

# Initialize Terraform
echo "Initializing Terraform..."
cd terraform
terraform init
cd ..
echo "✓ Terraform initialized"
echo ""

# Summary
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Configure GitHub Secrets:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo "   - EC2_SSH_KEY (from ~/.ssh/django-app-key)"
echo "   - DJANGO_SECRET_KEY"
echo ""
echo "2. Test locally (optional):"
echo "   cd terraform && terraform plan -var-file=terraform.tfvars"
echo ""
echo "3. Push to GitHub and watch the workflow:"
echo "   git push origin main"
echo ""
echo "4. Check GitHub Actions for deployment progress"
echo ""
echo "Full guide: see DEPLOYMENT_GUIDE.md"
echo ""
