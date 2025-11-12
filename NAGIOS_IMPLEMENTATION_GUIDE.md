# Nagios Monitoring Setup - Complete Implementation Guide

## 📋 What Was Created

I've created a **production-ready Nagios monitoring infrastructure** for your Django application on AWS. This includes everything needed for 24/7 monitoring, alerting, and infrastructure health tracking.

### 🎯 Key Components

1. **Nagios Core Server** (t3.small EC2 instance)
   - Central monitoring engine
   - Web dashboard at `/nagios`
   - Real-time alert management
   - Email & Slack notifications

2. **NRPE Agents** (on Django application server)
   - CPU, Memory, Disk, and Process monitoring
   - Secure communication with Nagios server
   - Custom Django-specific health checks

3. **11 Service Checks**
   - HTTP/HTTPS response time and availability
   - Gunicorn application server status
   - Nginx web server status
   - System CPU load
   - Memory utilization
   - Disk space
   - Swap usage
   - Running processes count
   - System uptime
   - SSH connectivity
   - ICMP ping

4. **Alert Mechanisms**
   - Email notifications (Gmail, Postfix, etc.)
   - Slack integration
   - Nagios dashboard with real-time status
   - Customizable alert thresholds

## 📁 File Structure

```
project_root/
│
├── terraform/
│   ├── monitoring.tf                    # Nagios server infrastructure
│   ├── monitoring_variables.tf          # Monitoring variables
│   ├── monitoring.tfvars.example        # Example configuration
│   └── nagios_user_data.sh             # Initial setup script
│
├── ansible/
│   ├── deploy_monitoring.yml            # Main deployment playbook
│   ├── monitoring_hosts.ini.j2          # Inventory template
│   │
│   └── roles/
│       ├── nagios-core/                # Nagios Core installation
│       │   ├── tasks/main.yml          # Installation steps
│       │   ├── handlers/main.yml       # Service handlers
│       │   ├── defaults/main.yml       # Default variables
│       │   └── templates/              # Jinja2 templates
│       │
│       ├── nagios-config/              # Nagios configuration
│       │   ├── tasks/main.yml          # Configuration tasks
│       │   └── templates/              # Config files (*.cfg.j2)
│       │
│       └── nrpe-client/                # NRPE agent setup
│           ├── tasks/main.yml          # Installation tasks
│           ├── defaults/main.yml       # Default variables
│           ├── handlers/main.yml       # Handlers
│           └── templates/              # Plugin scripts (*.sh.j2)
│
├── .github/
│   └── workflows/
│       ├── deploy.yml                  # Original Django deployment
│       └── deploy_with_monitoring.yml  # NEW: Combined deployment
│
└── documentation/
    ├── MONITORING_SETUP.md             # Detailed documentation
    └── MONITORING_QUICKSTART.md        # Quick start guide

```

## 🚀 Deployment Instructions

### Option A: Automatic Deployment via GitHub Actions (RECOMMENDED)

**Step 1: Add GitHub Secrets**

Go to your repository → **Settings → Secrets and variables → Actions** and add:

```
NAGIOS_ADMIN_PASSWORD      = "YourStrongPassword123!"
NAGIOS_EMAIL_ALERTS        = "your-email@example.com"
SLACK_WEBHOOK_URL          = "https://hooks.slack.com/services/..." (optional)
```

**Step 2: Trigger Deployment**

1. Go to **Actions** tab
2. Select **"Deploy Django App and Monitoring to AWS"**
3. Click **"Run workflow"**
4. Wait for completion (15-20 minutes)

**Step 3: Access Nagios**

After deployment:
1. Get the Nagios Server IP from workflow output
2. Open: `http://<NAGIOS_SERVER_IP>/nagios`
3. Login: `nagiosadmin` / `Your_Password`

---

### Option B: Local Deployment with Terraform & Ansible

**Step 1: Prepare Terraform Variables**

```bash
cd terraform

# Copy example file
cp monitoring.tfvars.example monitoring.tfvars

# Edit with your values
nano monitoring.tfvars
```

Required variables:
```hcl
nagios_admin_password = "YourStrongPassword123!"
nagios_email_alerts = "your-email@example.com"
slack_webhook_url = "https://hooks.slack.com/services/..."  # optional
enable_nagios_monitoring = true
```

**Step 2: Deploy Infrastructure**

```bash
# Initialize Terraform
terraform init

# Plan
terraform plan -var-file=monitoring.tfvars

# Apply
terraform apply -var-file=monitoring.tfvars

# Save outputs
terraform output > ../monitoring_outputs.txt
```

**Step 3: Configure and Deploy Nagios**

```bash
cd ../ansible

# Get IPs from Terraform outputs
export NAGIOS_IP=<from-terraform-output>
export DJANGO_IP=<from-terraform-output>
export NAGIOS_PRIVATE_IP=<from-terraform-output>
export DJANGO_PRIVATE_IP=<from-terraform-output>

# Create inventory
cat > monitoring_inventory.ini <<EOF
[nagios_servers]
nagios_server ansible_host=$NAGIOS_IP ansible_user=ubuntu

[django_servers]
django_app ansible_host=$DJANGO_IP ansible_user=ubuntu

[monitoring:children]
nagios_servers
django_servers

[monitoring:vars]
ansible_python_interpreter=/usr/bin/python3
nagios_admin_username=nagiosadmin
nagios_admin_password=YourPassword
nagios_email_alerts=your-email@example.com
django_app_private_ip=$DJANGO_PRIVATE_IP
nagios_server_private_ip=$NAGIOS_PRIVATE_IP
EOF

# Deploy
ansible-playbook -i monitoring_inventory.ini deploy_monitoring.yml \
  -e "nagios_admin_password=YourPassword"
```

## 📊 Monitoring Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS VPC (us-west-2)                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Nagios Server                      Django App Server        │
│  (t3.small)                         (t3.micro)               │
│  10.0.2.0/24                        10.0.1.0/24              │
│                                                               │
│  ┌──────────────────┐          ┌──────────────────┐         │
│  │  Nagios Core     │          │   Application    │         │
│  │  - Monitoring    │◄─NRPE──►│   - Gunicorn     │         │
│  │    Engine        │  (5666)  │   - Nginx        │         │
│  │  - Web Dashboard │  (TLS)   │   - NRPE Client  │         │
│  │  - Alerting      │          │   - Django       │         │
│  │  - Plugins       │          │                  │         │
│  └──────────────────┘          └──────────────────┘         │
│           │                                                   │
│      ┌────▼──────────┐                                       │
│      │   Alerting    │                                       │
│      ├───────────────┤                                       │
│      │ - Email       │                                       │
│      │ - Slack       │                                       │
│      │ - Dashboard   │                                       │
│      └───────────────┘                                       │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## 🔍 What Gets Monitored

### Service Checks (5-minute intervals)

| Service | Check | Warning | Critical |
|---------|-------|---------|----------|
| HTTP | Response time | 3s | 5s |
| Gunicorn | Port 8000 available | - | Timeout |
| Nginx | Port 80 available | - | Timeout |
| SSH | Port 22 available | - | Timeout |
| Ping | ICMP response | 20% loss | 60% loss |

### System Metrics via NRPE (5-10 min intervals)

| Metric | Warning | Critical | Notes |
|--------|---------|----------|-------|
| CPU Load | 5.0 | 10.0 | Per system |
| Memory Usage | 80% | 90% | RAM only |
| Disk Usage | 80% | 90% | Root filesystem |
| Swap Usage | 50% | 75% | If applicable |
| Process Count | 250 | 400 | System stability |
| System Uptime | Fresh reboot | - | Post-reboot check |

## 📧 Alert Configuration

### Email Setup

1. Nagios automatically sends emails via Postfix
2. Alerts go to: `NAGIOS_EMAIL_ALERTS` (from secrets)
3. Email subjects include:
   - Service name
   - Current state (WARNING, CRITICAL, RECOVERY)
   - Performance metrics
   - Hostname and IP

### Slack Setup

1. Create Slack Webhook:
   - Go to your Slack workspace
   - Add "Incoming Webhooks" app
   - Create new webhook
   - Copy the URL

2. Add to GitHub secrets:
   ```
   SLACK_WEBHOOK_URL = https://hooks.slack.com/services/...
   ```

3. Slack messages include:
   - Alert type and severity
   - Service/host information
   - Current metrics
   - Timestamp

## 🔧 Configuration Details

### Nagios Configuration Files

Located in `/etc/nagios/objects/`:

- **django_app_host.cfg**: Django server definition
- **django_app_services.cfg**: 11 service checks
- **aws_ec2_hostgroup.cfg**: Host grouping
- **custom_commands.cfg**: Check command definitions
- **contacts.cfg**: Contact and alert routing

### NRPE Configuration

Located in `/etc/nagios/nrpe.cfg` on Django server:

```cfg
# NRPE settings
server_port=5666
use_ssl=1
ssl_version=TLSv1_2
allow_arguments=1

# Allowed Nagios server
allowed_hosts=127.0.0.1,10.0.2.0

# Command definitions with thresholds
command[check_load]=/opt/nagios/libexec/check_load -w 15,10,5 -c 30,25,20
command[check_memory]=/usr/local/nagios/libexec/check_memory.sh -w 80 -c 90
command[check_disk_all]=/opt/nagios/libexec/check_disk -w 20 -c 10 -p /
```

## 📈 Using the Nagios Dashboard

### Login
- URL: `http://<NAGIOS_IP>/nagios`
- User: `nagiosadmin`
- Password: Your configured password

### Key Sections

1. **Hosts**
   - Shows all monitored servers
   - Green = UP, Red = DOWN
   - Click for details

2. **Services**
   - All service checks
   - Status: OK (green), WARNING (yellow), CRITICAL (red)
   - Check output and performance data
   - Last check time

3. **Status Map**
   - Visual representation of hosts
   - Network topology

4. **Tactical Monitoring**
   - Summary statistics
   - Unhandled problems
   - Alert history

5. **Alerts**
   - View and acknowledge alerts
   - Configure alert routing

## 🛠️ Maintenance Tasks

### Daily
- Review Nagios dashboard
- Check alert emails/Slack messages

### Weekly
- Verify all service checks are passing
- Check disk space on both servers
- Review NRPE connection status

### Monthly
- Analyze performance trends
- Update thresholds if needed
- Review and optimize alert settings
- Archive old logs

### Quarterly
- Update Nagios Core to latest stable version
- Update monitoring plugins
- Capacity planning
- Security audit

## 🐛 Troubleshooting

### Nagios not starting

```bash
# SSH to Nagios server
ssh -i ~/.ssh/id_rsa ubuntu@<NAGIOS_IP>

# Check configuration
sudo /opt/nagios/bin/nagios -v /etc/nagios/nagios.cfg

# View logs
sudo journalctl -u nagios -n 50
```

### NRPE connection errors

```bash
# On Django server
ssh ubuntu@<DJANGO_IP>

# Check NRPE status
sudo systemctl status nrpe

# Test manually
/opt/nagios/libexec/check_nrpe -H 127.0.0.1 -c check_load
```

### Alerts not sent

```bash
# Check mail service
sudo systemctl status postfix
sudo tail -f /var/log/mail.log

# Test mail
echo "Test" | mail -s "Test" your-email@example.com
```

### High CPU/Memory on Nagios

- Reduce check frequency
- Disable unnecessary checks
- Review Nagios configuration

## 🔐 Security Best Practices

1. **Strong Passwords**
   - Use 12+ characters with mixed case
   - Change default password immediately

2. **Network Security**
   - NRPE uses TLS encryption
   - Security groups restrict access
   - SSH key-based authentication

3. **Access Control**
   - Nagios dashboard has authentication
   - Consider IP whitelisting
   - Regular password rotation

4. **Data Protection**
   - Encrypt sensitive variables
   - Backup Nagios configuration
   - Securely store backups

## 📚 Documentation Files

- **MONITORING_SETUP.md**: Complete detailed guide
- **MONITORING_QUICKSTART.md**: Quick reference
- **This file**: Implementation overview

## 🎓 Learning Resources

- [Nagios Official Docs](https://assets.nagios.com/downloads/nagioscore/docs/)
- [NRPE Documentation](https://github.com/nagios-nrpe/nrpe)
- [Nagios Plugins](https://www.monitoring-plugins.org/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)

## ✅ Post-Deployment Checklist

- [ ] GitHub secrets added
- [ ] Workflow executed successfully
- [ ] Nagios dashboard accessible
- [ ] All service checks showing "OK"
- [ ] Email alerts received test message
- [ ] Slack notifications working (if configured)
- [ ] Nagios admin password changed from default
- [ ] SSH key pairs secured
- [ ] AWS credentials secured
- [ ] Documentation reviewed
- [ ] Alert thresholds adjusted for your workload
- [ ] Backup strategy configured

## 🆘 Getting Help

1. Check the detailed MONITORING_SETUP.md
2. Review Nagios logs:
   ```bash
   sudo tail -f /var/log/nagios/nagios.log
   ```
3. Check Ansible playbook output in GitHub Actions
4. Review Terraform state for resource details
5. Consult official documentation

## 📞 Support Contacts

- **Terraform Issues**: [Terraform GitHub](https://github.com/hashicorp/terraform)
- **Ansible Issues**: [Ansible GitHub](https://github.com/ansible/ansible)
- **AWS Issues**: [AWS Support](https://console.aws.amazon.com/support/)
- **Nagios Issues**: [Nagios Community](https://www.nagios.org/community/)

## 📝 Notes

- Monitoring infrastructure costs ~$10-15/month for Nagios server (t3.small)
- All passwords and sensitive data stored in GitHub secrets
- Terraform state stored locally (consider S3 backend for production)
- Monitoring works across availability zones
- Horizontally scalable to monitor multiple application instances

## 🎉 Success Indicators

Your monitoring is working correctly when:

✅ Nagios dashboard loads without errors
✅ All service checks display status
✅ Alert test emails arrive
✅ Slack notifications work
✅ NRPE data updates every 5-10 minutes
✅ Historical data available in Nagios
✅ Threshold violations trigger alerts

---

**Your Django application is now monitored 24/7!** 🚀

For questions or issues, refer to MONITORING_SETUP.md or contact your DevOps team.
