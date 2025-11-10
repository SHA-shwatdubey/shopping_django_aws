# Django Application AWS Deployment Guide

Complete DevOps workflow for deploying a Django application to AWS using Terraform, Ansible, and GitHub Actions.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [GitHub Secrets Configuration](#github-secrets-configuration)
4. [Terraform Setup](#terraform-setup)
5. [Ansible Configuration](#ansible-configuration)
6. [GitHub Actions Workflow](#github-actions-workflow)
7. [Deployment Process](#deployment-process)
8. [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
9. [Cost Optimization](#cost-optimization)
10. [Security Best Practices](#security-best-practices)

---

## Architecture Overview

```
┌─────────────────┐
│  GitHub Actions │
│    Workflow     │
└────────┬────────┘
         │
         ├─→ Terraform
         │   ├─ EC2 Instance (Ubuntu)
         │   ├─ Security Group (SSH, HTTP, HTTPS)
         │   ├─ Key Pair (SSH access)
         │   └─ Elastic IP (static IP)
         │
         └─→ Ansible Playbook
             ├─ Install Dependencies (Python, Nginx, etc.)
             ├─ Deploy Django App from GitHub
             ├─ Configure Gunicorn
             ├─ Configure Nginx
             └─ Start Services
```

**Components:**

- **Terraform**: Provisions AWS infrastructure (EC2, Security Group, Key Pair, Elastic IP)
- **Ansible**: Configures the EC2 instance and deploys the Django application
- **GitHub Actions**: Orchestrates the entire CI/CD pipeline

---

## Prerequisites

### Local Development Environment

1. **AWS Account** with appropriate IAM permissions
2. **Git** installed
3. **Terraform** (v1.6.0 or higher)
4. **Ansible** (v2.10 or higher)
5. **SSH Key Pair** for EC2 access

### AWS IAM Permissions Required

The AWS user needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeImages",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DescribeSecurityGroups",
        "ec2:CreateKeyPair",
        "ec2:DeleteKeyPair",
        "ec2:DescribeKeyPairs",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        "ec2:DescribeAddresses",
        "ec2:CreateTags",
        "ec2:DescribeTags",
        "ec2:DeleteTags"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## GitHub Secrets Configuration

GitHub Actions needs secure access to AWS credentials and SSH keys. Configure these secrets in your GitHub repository:

**Go to**: Repository → Settings → Secrets and variables → Actions

### Required Secrets

#### 1. **AWS_ACCESS_KEY_ID**
- **Type**: AWS Access Key ID
- **How to get it**:
  1. Go to AWS IAM Console
  2. Click "Users" → Your user
  3. Click "Security credentials" tab
  4. Click "Create access key"
  5. Copy the Access Key ID
- **Store in GitHub**: Paste the access key ID

#### 2. **AWS_SECRET_ACCESS_KEY**
- **Type**: AWS Secret Access Key
- **How to get it**:
  1. Same as above (step 4)
  2. Copy the Secret Access Key
  3. ⚠️ **This is only shown once** — save it securely
- **Store in GitHub**: Paste the secret access key

#### 3. **EC2_SSH_KEY**
- **Type**: Private SSH Key (for EC2 access)
- **How to get it**:
  1. Generate a new key pair or use existing one:
     ```bash
     ssh-keygen -t rsa -b 4096 -f ~/.ssh/django-app-key -N ""
     ```
  2. The private key is in `~/.ssh/django-app-key`
  3. The public key is in `~/.ssh/django-app-key.pub`
  4. Copy the **entire private key** (including `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`)
- **Store in GitHub**: 
  - Paste the entire private key content
  - Ensure there are no extra spaces or formatting issues

#### 4. **DJANGO_SECRET_KEY**
- **Type**: Django SECRET_KEY
- **How to generate it**:
  ```python
  from django.core.management.utils import get_random_secret_key
  print(get_random_secret_key())
  ```
  Or use an online tool: https://djecrety.ir/
- **Store in GitHub**: Paste the generated secret key

#### 5. **HOST_IP** (Optional)
- **Type**: Your machine's IP address (for SSH access restriction)
- **How to get it**:
  ```bash
  curl https://checkip.amazonaws.com
  ```
- **Store in GitHub**: Paste your IP address
- **Note**: If you don't set this, SSH access is open to the world (0.0.0.0/0)

### Example: How to Add Secrets

```bash
# On your local machine, read the private key
cat ~/.ssh/django-app-key

# Copy the output (entire key) to GitHub:
# 1. Go to Settings → Secrets and variables → Actions
# 2. Click "New repository secret"
# 3. Name: EC2_SSH_KEY
# 4. Value: (paste the private key)
# 5. Click "Add secret"
```

---

## Terraform Setup

### File Structure

```
terraform/
├── main.tf                    # Main infrastructure definition
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── user_data.sh              # EC2 initialization script
└── terraform.tfvars.example  # Example variables (copy and configure)
```

### Step 1: Configure Terraform Variables

1. **Copy the example file**:
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   ```

2. **Edit `terraform/terraform.tfvars`**:
   ```hcl
   aws_region       = "us-east-1"
   project_name     = "shoppinglyx"
   environment      = "dev"
   instance_type    = "t3.micro"  # Free tier eligible
   root_volume_size = 20
   
   # Replace with your public key path
   public_key_path = "~/.ssh/django-app-key.pub"
   
   # Restrict SSH to your IP (replace with your IP)
   allowed_ssh_cidr = ["YOUR_IP_ADDRESS/32"]
   
   use_elastic_ip = true
   ```

3. **Create SSH key pair** (if you haven't already):
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/django-app-key -N ""
   ```

### Step 2: Initialize Terraform

```bash
cd terraform
terraform init
```

### Step 3: Plan and Apply

```bash
# Validate configuration
terraform validate

# Preview changes
terraform plan -var-file=terraform.tfvars

# Apply changes (creates resources)
terraform apply -var-file=terraform.tfvars
```

### Step 4: Retrieve Outputs

```bash
# Get instance public IP
terraform output -raw instance_public_ip

# Get SSH connection string
terraform output -raw ssh_connection_string

# Get all outputs
terraform output
```

### Terraform Outputs Explanation

- **instance_id**: EC2 instance ID
- **instance_public_ip**: Public IP address of the instance
- **instance_private_ip**: Private IP address
- **elastic_ip**: Static Elastic IP (if created)
- **security_group_id**: Security group ID
- **key_pair_name**: Name of the SSH key pair
- **ssh_connection_string**: Ready-to-use SSH command
- **ansible_inventory**: Data for Ansible inventory

---

## Ansible Configuration

### File Structure

```
ansible/
├── site.yml                          # Main playbook
├── hosts.ini                         # Inventory (populated by GitHub Actions)
├── roles/
│   ├── dependencies/
│   │   └── tasks/main.yml           # Install system packages
│   ├── django-deploy/
│   │   ├── tasks/main.yml           # Deploy Django app
│   │   └── templates/django_env.j2  # Django environment template
│   ├── nginx-config/
│   │   ├── tasks/main.yml           # Configure Nginx
│   │   └── templates/nginx_django.j2 # Nginx config template
│   └── gunicorn-config/
│       ├── tasks/main.yml           # Configure Gunicorn
│       └── templates/
│           ├── gunicorn.service.j2  # Systemd service
│           └── gunicorn.socket.j2   # Systemd socket
```

### Roles Overview

#### 1. **dependencies** Role
- Installs Python 3.11, pip, virtualenv
- Installs Nginx
- Installs build tools and SSL libraries
- Installs certbot for Let's Encrypt

#### 2. **django-deploy** Role
- Clones Django repo from GitHub
- Creates Python virtual environment
- Installs Django and dependencies
- Runs migrations
- Collects static files

#### 3. **nginx-config** Role
- Configures Nginx as a reverse proxy
- Serves static files
- Proxies requests to Gunicorn
- Includes security headers

#### 4. **gunicorn-config** Role
- Creates Gunicorn systemd service
- Configures workers and binding
- Manages auto-restart

### Running Ansible Manually

```bash
# Create inventory file
cat > ansible/inventory.ini <<EOF
[django_servers]
django_server_1 ansible_host=YOUR_INSTANCE_IP ansible_user=ubuntu

[django_servers:vars]
ansible_python_interpreter=/usr/bin/python3
django_repo_url=https://github.com/YOUR_USERNAME/shoppinglyx.git
django_secret_key=YOUR_SECRET_KEY
EOF

# Run playbook
ansible-playbook \
  -i ansible/inventory.ini \
  -u ubuntu \
  --private-key ~/.ssh/django-app-key \
  -v \
  ansible/site.yml
```

---

## GitHub Actions Workflow

### Workflow File

**Location**: `.github/workflows/deploy.yml`

### Workflow Steps

1. **Checkout code** from main branch
2. **Terraform**:
   - Setup Terraform
   - Configure AWS credentials
   - Run `terraform init`
   - Run `terraform plan`
   - Run `terraform apply`
   - Extract instance IP
3. **Ansible**:
   - Setup Python
   - Install Ansible
   - Create SSH key from secrets
   - Create dynamic inventory
   - Wait for instance to be ready
   - Run playbook
   - Verify deployment

### Triggering the Workflow

The workflow automatically triggers when you:

1. **Push to main branch**:
   ```bash
   git add .
   git commit -m "Deploy Django app"
   git push origin main
   ```

2. **Manually trigger** (GitHub UI):
   - Go to Actions tab
   - Click "Deploy Django App to AWS"
   - Click "Run workflow"

### Viewing Workflow Logs

1. Go to **Actions** tab in your GitHub repository
2. Click on the workflow run
3. Click on **terraform** or **ansible** job
4. View detailed logs

---

## Deployment Process

### Step-by-Step Deployment

#### Option 1: Via GitHub Actions (Recommended)

1. **Ensure all secrets are configured** (see GitHub Secrets Configuration section)

2. **Push code to main branch**:
   ```bash
   git push origin main
   ```

3. **GitHub Actions automatically**:
   - Provisions EC2 instance
   - Deploys Django app
   - Configures Nginx and Gunicorn

4. **Monitor progress**:
   - Go to Actions tab
   - Click on your workflow run
   - View logs in real-time

#### Option 2: Manual Deployment (Local)

1. **Run Terraform**:
   ```bash
   cd terraform
   terraform apply -var-file=terraform.tfvars
   ```

2. **Get instance IP**:
   ```bash
   INSTANCE_IP=$(terraform output -raw instance_public_ip)
   echo "Instance IP: $INSTANCE_IP"
   ```

3. **Wait for instance** (30 seconds to 2 minutes):
   ```bash
   sleep 30
   ```

4. **Update Ansible inventory**:
   ```bash
   cat > ansible/inventory.ini <<EOF
   [django_servers]
   django_server_1 ansible_host=$INSTANCE_IP ansible_user=ubuntu
   
   [django_servers:vars]
   ansible_python_interpreter=/usr/bin/python3
   django_repo_url=https://github.com/rajsolodev/shoppinglyx.git
   django_secret_key=YOUR_SECRET_KEY
   EOF
   ```

5. **Run Ansible playbook**:
   ```bash
   ansible-playbook \
     -i ansible/inventory.ini \
     -u ubuntu \
     --private-key ~/.ssh/django-app-key \
     -v \
     ansible/site.yml
   ```

### Post-Deployment Verification

1. **Check services are running**:
   ```bash
   ssh -i ~/.ssh/django-app-key ubuntu@YOUR_INSTANCE_IP
   
   # On the instance:
   sudo systemctl status gunicorn
   sudo systemctl status nginx
   ```

2. **Access the application**:
   ```
   http://YOUR_INSTANCE_IP
   ```

3. **Check logs**:
   ```bash
   # Gunicorn logs
   sudo tail -f /var/log/gunicorn/access.log
   sudo tail -f /var/log/gunicorn/error.log
   
   # Nginx logs
   sudo tail -f /var/log/nginx/access.log
   sudo tail -f /var/log/nginx/error.log
   ```

---

## Monitoring and Troubleshooting

### Common Issues and Solutions

#### Issue 1: SSH Connection Timeout
**Problem**: Cannot SSH into the instance

**Solution**:
```bash
# 1. Check security group allows SSH from your IP
aws ec2 describe-security-groups \
  --group-ids YOUR_SG_ID \
  --region us-east-1

# 2. Check instance is running
aws ec2 describe-instances \
  --instance-ids YOUR_INSTANCE_ID \
  --region us-east-1

# 3. Wait 2-3 minutes for instance to fully boot
sleep 180

# 4. Try SSH with verbose output
ssh -vvv -i ~/.ssh/django-app-key ubuntu@YOUR_INSTANCE_IP
```

#### Issue 2: Ansible Connection Failed
**Problem**: Ansible cannot connect to the instance

**Solution**:
```bash
# 1. Verify instance is ready
ssh -o ConnectTimeout=5 ubuntu@YOUR_INSTANCE_IP "echo OK"

# 2. Check Ansible inventory
cat ansible/inventory.ini

# 3. Test Ansible connectivity
ansible -i ansible/inventory.ini django_servers -m ping

# 4. Run playbook with verbose mode
ansible-playbook \
  -i ansible/inventory.ini \
  -u ubuntu \
  --private-key ~/.ssh/django-app-key \
  -vvv \
  ansible/site.yml
```

#### Issue 3: Gunicorn Not Starting
**Problem**: Django app is not serving requests

**Solution**:
```bash
ssh -i ~/.ssh/django-app-key ubuntu@YOUR_INSTANCE_IP

# On the instance:
sudo systemctl status gunicorn
sudo journalctl -u gunicorn -n 50
sudo tail -f /var/log/gunicorn/error.log

# Restart service
sudo systemctl restart gunicorn
```

#### Issue 4: Nginx Returns 502 Bad Gateway
**Problem**: Nginx cannot connect to Gunicorn

**Solution**:
```bash
# Check Gunicorn is listening
sudo netstat -tulpn | grep gunicorn

# Check Nginx error log
sudo tail -f /var/log/nginx/error.log

# Verify Nginx config
sudo nginx -t

# Restart services
sudo systemctl restart gunicorn
sudo systemctl restart nginx
```

#### Issue 5: Database Migrations Failed
**Problem**: Django migrations didn't apply

**Solution**:
```bash
ssh -i ~/.ssh/django-app-key ubuntu@YOUR_INSTANCE_IP

# On the instance, activate venv and run manually
cd /var/www/django-app
source venv/bin/activate
python manage.py migrate --no-input
python manage.py collectstatic --no-input
```

### Accessing Logs

**Gunicorn Logs**:
```bash
ssh -i ~/.ssh/django-app-key ubuntu@YOUR_INSTANCE_IP
sudo tail -f /var/log/gunicorn/error.log
sudo tail -f /var/log/gunicorn/access.log
```

**Nginx Logs**:
```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

**System Logs**:
```bash
sudo journalctl -u gunicorn -n 100
sudo journalctl -u nginx -n 100
```

### Health Checks

**Check instance health**:
```bash
aws ec2 describe-instances \
  --instance-ids YOUR_INSTANCE_ID \
  --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress]'
```

**Test application**:
```bash
# Should return 200 status
curl -I http://YOUR_INSTANCE_IP

# Check specific endpoint
curl http://YOUR_INSTANCE_IP/admin/
```

---

## Cost Optimization

### AWS Tier Eligibility

The configuration uses free tier eligible resources:

- **t3.micro**: Free tier eligible (750 hours/month)
- **20GB EBS**: Free tier eligible (30GB/month)
- **Elastic IP**: Free when associated with running instance

### Cost Estimates (us-east-1)

| Resource | Free Tier | Paid |
|----------|-----------|------|
| t3.micro | 750 hrs/month | $0.01/hour |
| 20GB EBS | 30GB/month | $1.00/month |
| Elastic IP | Free (associated) | $3.65/month (unassociated) |
| Data transfer | 1GB/month out | $0.09/GB |

**Monthly cost**: ~$0-1 (if within free tier)

### Cost Saving Tips

1. **Stop instance** when not in use:
   ```bash
   aws ec2 stop-instances --instance-ids YOUR_INSTANCE_ID
   ```

2. **Terminate resources** when no longer needed:
   ```bash
   terraform destroy -var-file=terraform.tfvars
   ```

3. **Use auto-stop** via Lambda (advanced)

---

## Security Best Practices

### 1. SSH Access Control

**Restrict SSH to your IP**:

Edit `terraform/terraform.tfvars`:
```hcl
allowed_ssh_cidr = ["YOUR_IP_ADDRESS/32"]
```

Get your IP:
```bash
curl https://checkip.amazonaws.com
```

### 2. Environment Secrets

**Never commit secrets** to Git:

- `.env` files contain sensitive data
- Use GitHub Secrets (already configured)
- Rotate SECRET_KEY periodically

### 3. Django Security Settings

Edit `shoppinglyx/settings.py`:
```python
DEBUG = False  # Critical: Never enable in production
ALLOWED_HOSTS = ['your-domain.com', 'www.your-domain.com']
SECRET_KEY = os.getenv('SECRET_KEY')
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
```

### 4. HTTPS/SSL Configuration

**Using Let's Encrypt**:

```bash
ssh -i ~/.ssh/django-app-key ubuntu@YOUR_INSTANCE_IP

# On the instance:
sudo certbot certonly --nginx -d your-domain.com

# Update nginx config to use certificate
# Then restart Nginx
sudo systemctl restart nginx
```

Update `ansible/roles/nginx-config/templates/nginx_django.j2` to enable HTTPS block.

### 5. Regular Updates

**Keep system patched**:
```bash
ssh -i ~/.ssh/django-app-key ubuntu@YOUR_INSTANCE_IP

# On the instance:
sudo apt update && sudo apt upgrade -y
sudo reboot
```

### 6. Database Security

- Use separate RDS instance for production
- Configure DB subnet groups
- Use encryption at rest and in transit
- Enable automated backups

### 7. AWS IAM Hardening

- Create dedicated IAM user for CI/CD
- Use temporary credentials (STS)
- Enable MFA for AWS account
- Rotate access keys regularly

### 8. Firewall Rules

Current security group settings:
- **SSH (22)**: Restricted to your IP
- **HTTP (80)**: Open to world (0.0.0.0/0)
- **HTTPS (443)**: Open to world (0.0.0.0/0)
- **Outbound**: All traffic allowed

### 9. Monitoring & Logging

- Enable CloudWatch monitoring
- Set up CloudTrail for audit logs
- Use CloudWatch alarms for anomalies
- Regularly review access logs

### 10. Backup Strategy

```bash
# Backup database
ssh -i ~/.ssh/django-app-key ubuntu@YOUR_INSTANCE_IP
cd /var/www/django-app
source venv/bin/activate
python manage.py dumpdata > db-backup.json

# Download locally
scp -i ~/.ssh/django-app-key ubuntu@YOUR_INSTANCE_IP:/var/www/django-app/db-backup.json ./
```

---

## Next Steps

1. ✅ Configure GitHub Secrets
2. ✅ Customize Terraform variables
3. ✅ Test manual deployment (optional)
4. ✅ Push code to main branch
5. ✅ Monitor GitHub Actions workflow
6. ✅ Access deployed application
7. ✅ Configure SSL/HTTPS
8. ✅ Set up monitoring and alerts

---

## Support & Resources

- **Terraform Documentation**: https://www.terraform.io/docs
- **Ansible Documentation**: https://docs.ansible.com/
- **AWS Documentation**: https://docs.aws.amazon.com/
- **Django Documentation**: https://docs.djangoproject.com/

---

## License

MIT License - Feel free to use and modify for your projects.
