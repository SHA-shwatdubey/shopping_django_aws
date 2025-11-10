# Quick Reference Guide for Django AWS Deployment

## Directory Structure

```
.
├── terraform/              # Infrastructure as Code (AWS resources)
│   ├── main.tf            # EC2, Security Group, Key Pair, Elastic IP
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values (IP, SSH command, etc.)
│   ├── user_data.sh       # EC2 initialization script
│   ├── terraform.tfvars   # Your configuration (DO NOT commit)
│   └── backend.tf.example # S3 remote state configuration
│
├── ansible/               # Configuration Management
│   ├── site.yml          # Main playbook
│   ├── hosts.ini         # Inventory (auto-populated by CI/CD)
│   └── roles/
│       ├── dependencies/     # Install system packages
│       ├── django-deploy/    # Clone and deploy Django
│       ├── nginx-config/     # Configure web server
│       └── gunicorn-config/  # Configure app server
│
├── .github/
│   └── workflows/
│       └── deploy.yml    # GitHub Actions CI/CD pipeline
│
├── DEPLOYMENT_GUIDE.md              # Complete deployment guide
├── GITHUB_SECRETS_GUIDE.md          # Secrets configuration
├── setup-deployment.sh              # Setup assistant script
└── post-deploy.sh                   # Post-deployment configuration
```

## Quick Commands

### Setup & Initialization

```bash
# Make setup script executable
chmod +x setup-deployment.sh

# Run setup assistant (configures Terraform, generates SSH key)
./setup-deployment.sh
```

### Terraform Commands

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan -var-file=terraform.tfvars

# Apply changes (creates EC2 instance)
terraform apply -var-file=terraform.tfvars

# View outputs (IP, SSH command, etc.)
terraform output

# Get specific output
terraform output -raw instance_public_ip

# Destroy infrastructure (deletes EC2 instance)
terraform destroy -var-file=terraform.tfvars
```

### Ansible Commands

```bash
cd ansible

# Test connectivity to hosts
ansible -i inventory.ini django_servers -m ping

# Run playbook in check mode (dry-run)
ansible-playbook -i inventory.ini -u ubuntu --private-key ~/.ssh/django-app-key --check site.yml

# Run playbook (actual deployment)
ansible-playbook -i inventory.ini -u ubuntu --private-key ~/.ssh/django-app-key -v site.yml

# Run specific role only
ansible-playbook -i inventory.ini -u ubuntu --private-key ~/.ssh/django-app-key --tags nginx site.yml

# Run playbook with extra variables
ansible-playbook -i inventory.ini -u ubuntu --private-key ~/.ssh/django-app-key -e "django_secret_key=YOUR_KEY" site.yml
```

### SSH & Remote Access

```bash
# SSH into EC2 instance
ssh -i ~/.ssh/django-app-key ubuntu@YOUR_INSTANCE_IP

# Copy file to instance
scp -i ~/.ssh/django-app-key /local/path ubuntu@YOUR_INSTANCE_IP:/remote/path

# Copy file from instance
scp -i ~/.ssh/django-app-key ubuntu@YOUR_INSTANCE_IP:/remote/path /local/path

# SSH with verbose output (debugging)
ssh -vvv -i ~/.ssh/django-app-key ubuntu@YOUR_INSTANCE_IP
```

### Service Management (on EC2 instance)

```bash
# Check service status
sudo systemctl status gunicorn
sudo systemctl status nginx

# Restart services
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# View logs
sudo tail -f /var/log/gunicorn/error.log
sudo tail -f /var/log/nginx/error.log

# View recent logs
sudo journalctl -u gunicorn -n 50
sudo journalctl -u nginx -n 50
```

### GitHub Actions Workflow

```bash
# Manually trigger workflow (via GitHub UI)
# 1. Go to Actions tab
# 2. Click "Deploy Django App to AWS"
# 3. Click "Run workflow"

# Or via GitHub CLI:
gh workflow run deploy.yml

# View workflow logs
gh run list
gh run view RUN_ID --log
```

### Secrets Management

```bash
# View all GitHub Secrets (via CLI)
gh secret list

# Set a secret via CLI
gh secret set SECRET_NAME --body "SECRET_VALUE"

# Delete a secret
gh secret delete SECRET_NAME

# View secret values (via GitHub UI only, for security)
# Go to Settings → Secrets and variables → Actions
```

## Common Troubleshooting

### Cannot connect to EC2 instance (SSH timeout)

```bash
# 1. Check instance is running
aws ec2 describe-instances --instance-ids INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name'

# 2. Check security group allows SSH from your IP
aws ec2 describe-security-groups --group-ids SECURITY_GROUP_ID

# 3. Wait for instance to fully boot (2-3 minutes)
sleep 180

# 4. Test with verbose SSH
ssh -vvv -i ~/.ssh/django-app-key ubuntu@YOUR_IP
```

### Ansible cannot connect

```bash
# 1. Test connectivity
ansible -i inventory.ini django_servers -m ping

# 2. Check inventory file
cat ansible/inventory.ini

# 3. Verify SSH key
ls -la ~/.ssh/django-app-key
chmod 600 ~/.ssh/django-app-key

# 4. Test SSH directly
ssh -i ~/.ssh/django-app-key ubuntu@YOUR_IP "echo Test"
```

### Application not responding (502 Bad Gateway)

```bash
# SSH into instance
ssh -i ~/.ssh/django-app-key ubuntu@YOUR_IP

# Check Gunicorn status
sudo systemctl status gunicorn
sudo systemctl restart gunicorn

# Check Nginx config
sudo nginx -t

# View error logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/gunicorn/error.log
```

### Database migration errors

```bash
# SSH into instance
ssh -i ~/.ssh/django-app-key ubuntu@YOUR_IP

# Navigate to app directory
cd /var/www/django-app
source venv/bin/activate

# Run migrations manually
python manage.py migrate --no-input

# Check migration status
python manage.py showmigrations
```

## Cost Tracking

```bash
# Estimate AWS costs
aws ce get-cost-and-usage \
  --time-period Start=2025-01-01,End=2025-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Stop instance (save cost when not in use)
aws ec2 stop-instances --instance-ids INSTANCE_ID

# Terminate instance (permanent deletion)
terraform destroy -var-file=terraform.tfvars
```

## Deployment Checklist

Before deploying to production:

- [ ] All secrets configured in GitHub
- [ ] Terraform variables set correctly
- [ ] SSH key pair generated and backed up
- [ ] Django settings configured for production
- [ ] Database migrations tested locally
- [ ] Static files configured
- [ ] Nginx HTTPS/SSL configured
- [ ] Domain name configured (if applicable)
- [ ] Backup strategy documented
- [ ] Monitoring/alerts set up
- [ ] Security group rules reviewed
- [ ] Cost budget set in AWS

## Important Files

| File | Purpose |
|------|---------|
| `terraform/terraform.tfvars` | Your Terraform variables (DO NOT commit) |
| `.env` on server | Django environment variables |
| `~/.ssh/django-app-key` | Private SSH key (keep secure) |
| GitHub Secrets | AWS credentials, SSH key, Django secret |

## Documentation

- Full deployment guide: `DEPLOYMENT_GUIDE.md`
- Secrets configuration: `GITHUB_SECRETS_GUIDE.md`
- This file: `QUICK_REFERENCE.md`

## Getting Help

1. Check error messages in GitHub Actions logs
2. Review `DEPLOYMENT_GUIDE.md` troubleshooting section
3. Check Ansible playbook output for configuration issues
4. Review service logs on EC2 instance
5. Check AWS CloudWatch/CloudTrail for AWS-related issues

---

**Last Updated**: November 2025
