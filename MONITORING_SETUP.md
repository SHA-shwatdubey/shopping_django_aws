# Nagios Monitoring Setup Documentation

## Overview

This Nagios monitoring infrastructure provides comprehensive monitoring of your Django application and AWS infrastructure. It includes:

- **Nagios Core**: Centralized monitoring server
- **NRPE (Nagios Remote Plugin Executor)**: Agent for remote system monitoring
- **Service Checks**: HTTP, CPU, Memory, Disk, Process, Uptime monitoring
- **Alerting**: Email and Slack notifications
- **Web Dashboard**: Real-time visualization of system health

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Monitoring Architecture                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────┐          ┌──────────────────────┐ │
│  │  Nagios Core Server  │          │  Django App Server   │ │
│  │  (t3.small)          │◄─NRPE──►│  (t3.micro)          │ │
│  │  - Monitoring Engine │  (5666)  │  - NRPE Agent        │ │
│  │  - Web Dashboard     │          │  - Local Checks      │ │
│  │  - Alerting          │          │  - Gunicorn/Nginx    │ │
│  │  - Plugins           │          │                      │ │
│  └──────────────────────┘          └──────────────────────┘ │
│           │                                                   │
│           │                                                   │
│      ┌────▼─────────┐                                        │
│      │   Alerts     │                                        │
│      ├──────────────┤                                        │
│      │ - Email      │                                        │
│      │ - Slack      │                                        │
│      │ - Dashboard  │                                        │
│      └──────────────┘                                        │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Files Structure

```
terraform/
├── monitoring.tf                    # Nagios server and security groups
├── monitoring_variables.tf          # Monitoring-related variables
├── monitoring.tfvars.example        # Example variables file
└── nagios_user_data.sh             # Initial Nagios server setup script

ansible/
├── deploy_monitoring.yml            # Main monitoring playbook
├── monitoring_hosts.ini.j2          # Monitoring hosts inventory
│
├── roles/
│   ├── nagios-core/                # Nagios Core installation
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   ├── defaults/main.yml
│   │   └── templates/
│   │
│   ├── nagios-config/              # Nagios configuration
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   └── templates/
│   │       ├── django_app_host.cfg.j2
│   │       ├── django_app_services.cfg.j2
│   │       ├── aws_ec2_hostgroup.cfg.j2
│   │       ├── custom_commands.cfg.j2
│   │       ├── contacts.cfg.j2
│   │       ├── check_django_health.j2
│   │       └── check_cpu_load.j2
│   │
│   └── nrpe-client/                # NRPE client setup
│       ├── tasks/main.yml
│       ├── handlers/main.yml
│       ├── defaults/main.yml
│       └── templates/
│           ├── nrpe.cfg.j2
│           ├── check_memory.sh.j2
│           ├── check_disk.sh.j2
│           ├── check_uptime.sh.j2
│           └── check_cpu_load.sh.j2
```

## Quick Start

### 1. Prerequisites

- Terraform >= 1.0
- Ansible >= 2.10
- AWS credentials configured
- SSH key pair for EC2 instances
- Nagios admin password (set in GitHub secrets or terraform.tfvars)

### 2. Deploy Nagios Infrastructure

#### Step 1: Update Terraform variables

```bash
cd terraform

# Copy and edit the monitoring variables
cp monitoring.tfvars.example monitoring.tfvars

# Edit with your settings
nano monitoring.tfvars
```

Required variables in `monitoring.tfvars`:
```hcl
nagios_admin_password       = "Your-Strong-Password-Here"
nagios_email_alerts         = "your-email@example.com"
slack_webhook_url           = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"  # Optional
enable_nagios_monitoring    = true
```

#### Step 2: Apply Terraform

```bash
# Initialize Terraform
terraform init

# Plan the monitoring infrastructure
terraform plan -var-file=monitoring.tfvars

# Apply the changes
terraform apply -var-file=monitoring.tfvars
```

Terraform will output:
- `nagios_server_public_ip`: IP to access Nagios dashboard
- `nagios_web_url`: Direct URL to Nagios
- `django_app_private_ip`: Internal IP of Django server (for Nagios)

#### Step 3: Configure Ansible

```bash
cd ansible

# Generate inventory from Terraform outputs
export NAGIOS_SERVER_IP=$(terraform -chdir=../terraform output -raw nagios_server_public_ip)
export DJANGO_APP_IP=$(terraform -chdir=../terraform output -raw django_app_private_ip)
export NAGIOS_SERVER_PRIVATE_IP=$(terraform -chdir=../terraform output -raw nagios_server_private_ip)

# Edit the inventory template
cat monitoring_hosts.ini.j2 > monitoring_hosts.ini
```

#### Step 4: Deploy Nagios

```bash
# Run the monitoring playbook
ansible-playbook -i monitoring_hosts.ini deploy_monitoring.yml \
  -e "nagios_admin_password=YOUR_PASSWORD" \
  -e "nagios_email_alerts=your-email@example.com"
```

### 3. Access Nagios Dashboard

After deployment completes:

1. Navigate to: `http://<nagios_server_public_ip>/nagios`
2. Login with:
   - Username: `nagiosadmin`
   - Password: `Your set password`
3. Explore the dashboard and monitoring data

## Monitoring Checks

### Django Application Checks

| Check Name | Interval | Threshold | Alert Type |
|-----------|----------|-----------|-----------|
| HTTP Response | 5 min | 1s warn / 3s crit | Email/Slack |
| Gunicorn Status | 5 min | TCP timeout | Email/Slack |
| Nginx Status | 5 min | TCP timeout | Email/Slack |
| SSH Connectivity | 10 min | Connection fail | Email/Slack |
| ICMP Ping | 5 min | Packet loss 20% | Email/Slack |

### System Checks via NRPE

| Check Name | Interval | Warning | Critical | Alert |
|-----------|----------|---------|----------|-------|
| CPU Load | 5 min | 5.0 | 10.0 | Email/Slack |
| Memory Usage | 5 min | 80% | 90% | Email/Slack |
| Disk Usage | 10 min | 80% | 90% | Email/Slack |
| Swap Usage | 10 min | 50% | 75% | Email/Slack |
| Process Count | 10 min | 250 | 400 | Email/Slack |
| System Uptime | 30 min | Fresh reboot | - | Email/Slack |

## Configuration Files

### Nagios Configuration Files

Generated in `/etc/nagios/objects/`:

- `django_app_host.cfg`: Django server host definition
- `django_app_services.cfg`: Service checks for Django
- `aws_ec2_hostgroup.cfg`: EC2 instance groups
- `custom_commands.cfg`: Custom check commands
- `contacts.cfg`: Alert contacts and groups

### NRPE Configuration

On Django server at `/etc/nagios/nrpe.cfg`:
- Defines allowed commands
- Configures NRPE server port (5666)
- Sets SSL/TLS encryption
- Defines check parameters

## Alert Configuration

### Email Alerts

Alerts are sent to the address configured in:
```hcl
nagios_email_alerts = "your-email@example.com"
```

Alert types:
- Service warnings (yellow)
- Service critical (red)
- Service recovery (green)
- Host down/unreachable

### Slack Integration

To enable Slack alerts:

1. Create a Slack Webhook URL from your workspace
2. Add to GitHub secrets: `SLACK_WEBHOOK_URL`
3. Update Terraform variables:
```hcl
slack_webhook_url = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

4. Slack alerts will trigger for:
   - Critical service failures
   - Host unavailability
   - Recovery notifications

## GitHub Actions Integration

The monitoring is integrated into your CI/CD pipeline. Add this job to your `.github/workflows/deploy.yml`:

```yaml
- name: Deploy Monitoring
  if: github.ref == 'refs/heads/main'
  run: |
    # Extract Terraform outputs
    export NAGIOS_SERVER_IP=$(cd terraform && terraform output -raw nagios_server_public_ip)
    export DJANGO_APP_IP=$(cd terraform && terraform output -raw django_app_private_ip)
    
    # Deploy Nagios
    cd ansible
    ansible-playbook -i monitoring_hosts.ini deploy_monitoring.yml \
      -e "nagios_admin_password=${{ secrets.NAGIOS_ADMIN_PASSWORD }}"
```

## Maintenance Tasks

### Daily

- Monitor Nagios dashboard for alerts
- Check alert emails/Slack messages

### Weekly

- Review service check results
- Verify disk space availability on both servers
- Check Nagios log files for errors

### Monthly

- Update monitoring thresholds based on baseline metrics
- Review and optimize alert configurations
- Archive old log files

### Quarterly

- Update Nagios Core to latest stable version
- Review and update check plugins
- Capacity planning based on trending data

## Troubleshooting

### Nagios Service Not Starting

```bash
# SSH to Nagios server
ssh -i your-key ubuntu@<nagios_ip>

# Check Nagios configuration validity
/opt/nagios/bin/nagios -v /etc/nagios/nagios.cfg

# View service logs
sudo systemctl status nagios
sudo journalctl -u nagios -n 50
```

### NRPE Connection Issues

```bash
# On Django server, check NRPE status
sudo systemctl status nrpe
sudo systemctl restart nrpe

# Test NRPE from Nagios server
/opt/nagios/libexec/check_nrpe -H <django_private_ip> -c check_load
```

### Alerts Not Being Sent

```bash
# Check mail service on Nagios server
sudo systemctl status postfix
sudo tail -f /var/log/mail.log

# Test Slack webhook
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test message"}' \
  $SLACK_WEBHOOK_URL
```

### Web Dashboard Not Accessible

```bash
# Check Apache status
sudo systemctl status apache2
sudo apache2ctl configtest

# Check Nagios CGI permissions
ls -la /opt/nagios/sbin/
sudo chown -R nagios:nagios /opt/nagios
```

## Performance Tuning

### Increase Check Frequency (more aggressive monitoring)

Edit service checks in `/etc/nagios/objects/django_app_services.cfg`:

```cfg
define service {
    ...
    check_interval          5      # Reduce this (in minutes)
    retry_interval          1      # Retry faster on failure
    ...
}
```

### Reduce Check Frequency (lower resource usage)

```cfg
define service {
    ...
    check_interval          30     # Increase for less frequent checks
    retry_interval          5
    ...
}
```

### Adjust Alert Thresholds

Edit thresholds in service definitions:

```cfg
check_command           check_http!localhost!80!-w 5 -c 10   # Increase tolerance
```

## Security Considerations

### Firewall Rules

The setup creates AWS security groups:
- `<project>-nagios-sg`: Nagios server security group
  - Allows port 80 (HTTP)
  - Allows port 443 (HTTPS) 
  - Allows port 5666 (NRPE) from Django server only

- `<project>-nagios-nrpe-sg`: NRPE client security group
  - Allows port 5666 from Nagios server only

### NRPE Encryption

NRPE uses SSL/TLS encryption by default. Communication is encrypted between:
- Nagios server → NRPE clients
- NRPE clients → Nagios server

### Web Dashboard Security

- Use strong passwords for Nagios web interface
- Consider adding HTTPS with Let's Encrypt
- Restrict dashboard access by IP if possible
- Change default credentials after first login

## Scaling to Multiple Servers

To monitor additional servers:

1. Create new host configuration in `/etc/nagios/objects/`:

```cfg
define host {
    use                     linux-server
    host_name               new-server
    address                 10.0.1.5
    hostgroups              django-servers
    contact_groups          admins
}
```

2. Install NRPE on the new server

3. Reload Nagios configuration

## Backup and Recovery

### Backup Nagios Configuration

```bash
# Backup Nagios directory
tar -czf nagios_backup_$(date +%Y%m%d).tar.gz /etc/nagios /opt/nagios

# Upload to S3
aws s3 cp nagios_backup_*.tar.gz s3://your-backup-bucket/
```

### Restore Configuration

```bash
# Download backup
aws s3 cp s3://your-backup-bucket/nagios_backup_*.tar.gz .

# Extract
tar -xzf nagios_backup_*.tar.gz -C /

# Restart services
sudo systemctl restart nagios apache2
```

## Additional Resources

- [Nagios Core Documentation](https://assets.nagios.com/downloads/nagioscore/docs/)
- [NRPE Documentation](https://github.com/nagios-nrpe/nrpe)
- [Nagios Plugins](https://www.monitoring-plugins.org/)
- [AWS Monitoring Best Practices](https://docs.aws.amazon.com/general/latest/gr/monitoring_overview.html)

## Support

For issues or questions:
1. Check Nagios logs: `/var/log/nagios/nagios.log`
2. Review Ansible playbook output
3. Consult Nagios documentation
4. Check AWS security groups and network ACLs

## License

This monitoring setup is part of the Django Shopping application deployment.
