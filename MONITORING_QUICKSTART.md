# Quick Start Guide: Nagios Monitoring Setup

## 📋 Prerequisites

Before deploying Nagios monitoring, ensure you have:

- ✅ AWS Account with credentials
- ✅ GitHub Repository with secrets configured
- ✅ EC2 key pair (downloaded and saved as `~/.ssh/id_rsa`)
- ✅ Terraform >= 1.0 installed locally (for testing)
- ✅ Ansible >= 2.10 installed locally (for testing)

## 🚀 5-Minute Setup

### Step 1: Add GitHub Secrets

Go to your repository **Settings → Secrets and variables → Actions** and add these secrets:

```
AWS_ACCESS_KEY_ID              = Your AWS Access Key
AWS_SECRET_ACCESS_KEY          = Your AWS Secret Key  
EC2_SSH_KEY                    = Your EC2 private key contents
DJANGO_SECRET_KEY              = Your Django secret key
NAGIOS_ADMIN_PASSWORD          = Your Nagios password (must be strong)
NAGIOS_EMAIL_ALERTS            = your-email@example.com
SLACK_WEBHOOK_URL              = https://hooks.slack.com/services/YOUR/WEBHOOK (optional)
```

### Step 2: Deploy from GitHub Actions

1. Go to your repository → **Actions**
2. Find and click **"Deploy Django App and Monitoring to AWS"**
3. Click **"Run workflow"** → **Run workflow**
4. Wait for all jobs to complete (approximately 15-20 minutes)

Monitor the deployment:
- ✅ **Terraform Plan & Apply** - Creates EC2 instances and security groups
- ✅ **Deploy Django Application** - Installs Django, Gunicorn, Nginx
- ✅ **Deploy Nagios Monitoring** - Installs Nagios Core and NRPE agents

### Step 3: Access Nagios Dashboard

After deployment completes:

1. Note the **Nagios Server IP** from GitHub Actions output
2. Open browser: `http://<NAGIOS_SERVER_IP>/nagios`
3. Login with:
   - **Username**: `nagiosadmin`
   - **Password**: Your `NAGIOS_ADMIN_PASSWORD` from secrets

### Step 4: Verify Monitoring

In Nagios dashboard:
1. Click **"Services"** in the left menu
2. Verify all Django app checks are "OK" (green)
3. Check **"Hosts"** - both servers should be monitored

## 📊 What Gets Monitored

### Django Application Checks
- ✅ HTTP Response (port 80/443)
- ✅ Gunicorn Application Server (port 8000)
- ✅ Nginx Web Server (port 80)
- ✅ SSH Connectivity (port 22)
- ✅ ICMP Ping

### System Metrics (via NRPE)
- ✅ CPU Load Average (warning: 5.0, critical: 10.0)
- ✅ Memory Usage (warning: 80%, critical: 90%)
- ✅ Disk Usage (warning: 80%, critical: 90%)
- ✅ Swap Usage (warning: 50%, critical: 75%)
- ✅ Process Count (warning: 250, critical: 400)
- ✅ System Uptime

### Alert Channels
- 📧 Email Notifications
- 🔔 Slack Notifications (if configured)
- 📱 Nagios Dashboard

## 🔄 Monitoring Flow

```
┌─────────────────────────────┐
│  Nagios Server (Monitoring) │
│  ├─ Checks Django App       │
│  ├─ Receives NRPE data      │
│  └─ Triggers Alerts         │
└──────────────┬──────────────┘
               │
      ┌────────┼────────┐
      │        │        │
   Email    Slack   Dashboard
```

## 📱 Slack Integration (Optional)

To receive Slack alerts:

1. Create a Slack Webhook:
   - Go to your Slack workspace
   - Install "Incoming Webhooks" app
   - Create new webhook → Copy URL

2. Add to GitHub secrets:
   - **SLACK_WEBHOOK_URL** = Your webhook URL

3. Re-run deployment - Slack alerts will now work

## 🔑 Important Credentials

Keep these safe:
- 🔒 `NAGIOS_ADMIN_PASSWORD` - Nagios web interface
- 🔒 EC2 SSH Key - SSH access to servers
- 🔒 AWS Credentials - Infrastructure access

**Never commit these to GitHub!**

## 📈 Common Tasks

### Check Nagios Logs

```bash
# SSH to Nagios server
ssh -i ~/.ssh/id_rsa ubuntu@<NAGIOS_IP>

# View Nagios status
sudo systemctl status nagios

# View logs
sudo tail -f /var/log/nagios/nagios.log
```

### Check Django Server Status

```bash
# SSH to Django server  
ssh -i ~/.ssh/id_rsa ubuntu@<DJANGO_IP>

# Check services
sudo systemctl status nginx
sudo systemctl status gunicorn

# View application logs
sudo tail -f /var/log/nginx/access.log
```

### Update Monitoring Thresholds

1. SSH to Nagios server
2. Edit: `/etc/nagios/objects/django_app_services.cfg`
3. Change thresholds (e.g., CPU load, memory)
4. Reload Nagios:
   ```bash
   sudo systemctl reload nagios
   ```

### Test Email Alerts

```bash
# SSH to Nagios server
ssh ubuntu@<NAGIOS_IP>

# Send test email
echo "Test email" | mail -s "Nagios Test" <your-email>
```

## ❌ Troubleshooting

### Nagios dashboard not loading

```bash
# Check Nagios service
sudo systemctl status nagios

# Check Apache
sudo systemctl status apache2

# Check logs
sudo tail -f /var/log/apache2/error.log
```

### NRPE connection errors

```bash
# On Django server, check NRPE
sudo systemctl status nrpe

# Test NRPE from Nagios
/opt/nagios/libexec/check_nrpe -H <DJANGO_PRIVATE_IP> -c check_load
```

### Alerts not being sent

```bash
# Check mail service
sudo systemctl status postfix
sudo tail -f /var/log/mail.log

# Test mail
echo "Test" | mail -s "Test" your-email@example.com
```

### Performance issues

1. **High CPU on Nagios**: Reduce check frequency
2. **Network issues**: Check security groups
3. **Slow NRPE**: Check network latency

## 📚 Next Steps

1. ✅ Configure Slack webhooks for better alerting
2. ✅ Set up custom check thresholds based on your app
3. ✅ Enable HTTPS on Nagios dashboard
4. ✅ Add additional monitored servers
5. ✅ Schedule regular backups

## 🆘 Support

For issues:

1. Check `MONITORING_SETUP.md` for detailed documentation
2. Review Nagios logs on the monitoring server
3. Check GitHub Actions workflow output
4. Review Terraform and Ansible outputs

## 📞 Getting Help

- **Nagios Docs**: https://assets.nagios.com/downloads/nagioscore/docs/
- **AWS Docs**: https://docs.aws.amazon.com/ec2/
- **Terraform Docs**: https://www.terraform.io/docs
- **Ansible Docs**: https://docs.ansible.com/

---

**Deployment successful!** Your Django application is now being monitored 24/7 by Nagios. 🎉
