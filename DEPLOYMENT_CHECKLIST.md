# 🚀 Nagios Monitoring - Deployment Checklist

## Pre-Deployment Setup

### GitHub Repository Configuration
- [ ] Repository: `SHA-shwatdubey/shopping_django_aws`
- [ ] Branch: `main` (default)
- [ ] All code committed and pushed
- [ ] No uncommitted changes

### GitHub Secrets Configuration

Go to: **Settings → Secrets and variables → Actions → New repository secret**

Add these secrets (required):

```
Name: AWS_ACCESS_KEY_ID
Value: [Your AWS Access Key ID]
Status: ✅ Added
```

```
Name: AWS_SECRET_ACCESS_KEY
Value: [Your AWS Secret Access Key]
Status: ✅ Added
```

```
Name: EC2_SSH_KEY
Value: [Full contents of your EC2 private key file]
Status: ✅ Added
```

```
Name: DJANGO_SECRET_KEY
Value: [Your Django SECRET_KEY]
Status: ✅ Added
```

```
Name: NAGIOS_ADMIN_PASSWORD
Value: [Strong password - 12+ chars, mixed case, numbers, symbols]
Status: ✅ Added
```

```
Name: NAGIOS_EMAIL_ALERTS
Value: [Your email address for alerts]
Status: ✅ Added
```

```
Name: SLACK_WEBHOOK_URL
Value: [Your Slack webhook URL] (optional)
Status: ✅ Added
```

### Pre-Deployment Verification

- [ ] All 6 required secrets added to GitHub
- [ ] Secrets are not visible in code
- [ ] AWS credentials have necessary permissions
- [ ] EC2 key pair is secure and accessible
- [ ] Email address is valid and monitored
- [ ] Slack webhook working (if configured)

---

## Deployment Execution

### Step 1: Trigger the Workflow

1. [ ] Go to your GitHub repository
2. [ ] Click **"Actions"** tab
3. [ ] Find **"Deploy Django App and Monitoring to AWS"** workflow
4. [ ] Click the workflow name
5. [ ] Click **"Run workflow"** button
6. [ ] Select **"Run workflow"** in dropdown

### Step 2: Monitor Deployment Progress

The workflow has 4 jobs. Monitor each:

1. **Terraform Plan & Apply** (5-10 minutes)
   - [ ] Starts successfully
   - [ ] EC2 instances created
   - [ ] Security groups configured
   - [ ] Outputs generated
   - Status: ✅ Success

2. **Deploy Django Application** (5-10 minutes)
   - [ ] Python dependencies installed
   - [ ] Django app deployed
   - [ ] Gunicorn started
   - [ ] Nginx configured
   - Status: ✅ Success

3. **Deploy Nagios Monitoring** (5-10 minutes)
   - [ ] Nagios Core installed
   - [ ] NRPE agent installed
   - [ ] Configurations applied
   - [ ] Services started
   - Status: ✅ Success

4. **Notifications Sent** (< 1 minute)
   - [ ] Slack notification received (if configured)
   - [ ] Display of URLs and credentials
   - Status: ✅ Success

**Total Duration**: 20-30 minutes

### Step 3: Retrieve Deployment Information

From the workflow output, note down:

```
Django Instance IP:     ___________________
Django Instance ID:     ___________________
Nagios Server IP:       ___________________
Nagios Server ID:       ___________________
```

Or from Terraform:
```bash
cd terraform
terraform output nagios_server_public_ip
terraform output django_app_private_ip
terraform output nagios_web_url
```

---

## Post-Deployment Verification

### 1. Access Nagios Dashboard

```
URL: http://<NAGIOS_SERVER_IP>/nagios
Username: nagiosadmin
Password: [Your NAGIOS_ADMIN_PASSWORD]
```

- [ ] Dashboard loads successfully
- [ ] No errors in page
- [ ] All navigation menus visible
- [ ] Login successful

### 2. Verify All Service Checks

In Nagios, navigate to **Services** section:

```
Expected Checks:
✅ HTTP Response Check          [Status: OK]
✅ Gunicorn Application Server  [Status: OK]
✅ Nginx Web Server             [Status: OK]
✅ CPU Load                     [Status: OK]
✅ Memory Usage                 [Status: OK]
✅ Disk Usage                   [Status: OK]
✅ Swap Usage                   [Status: OK]
✅ Process Count                [Status: OK]
✅ System Uptime                [Status: OK]
✅ SSH Connectivity             [Status: OK]
✅ ICMP Ping                    [Status: OK]
```

- [ ] All 11 checks visible
- [ ] All checks show "OK" status
- [ ] No "PENDING" checks
- [ ] Performance data displayed

### 3. Test Email Alerts

Manually trigger a test alert:

```bash
# SSH to Nagios server
ssh -i ~/.ssh/id_rsa ubuntu@<NAGIOS_SERVER_IP>

# Send test notification
sudo systemctl restart nagios
```

- [ ] Test email received within 5 minutes
- [ ] Email contains host/service information
- [ ] Email is readable and formatted well

### 4. Test Slack Alerts (if configured)

If Slack webhook is configured:

- [ ] Slack notification received for deployment
- [ ] Message includes links and status
- [ ] Formatting is clear and readable

### 5. Verify Service Status

```bash
# SSH to Django server
ssh -i ~/.ssh/id_rsa ubuntu@<DJANGO_SERVER_IP>

# Verify services
sudo systemctl status gunicorn    # Should be active
sudo systemctl status nginx       # Should be active
sudo systemctl status nrpe        # Should be active
```

- [ ] Gunicorn running on port 8000
- [ ] Nginx running on port 80
- [ ] NRPE agent running on port 5666

### 6. Test Django Application

```bash
curl http://<DJANGO_SERVER_IP>/
```

- [ ] Web server responds
- [ ] No 500 errors
- [ ] Application is accessible

### 7. Verify Security Groups

In AWS Console → EC2 → Security Groups:

- [ ] `shoppinglyx-prod-nagios-sg` exists
- [ ] `shoppinglyx-prod-nagios-nrpe-sg` exists
- [ ] Inbound rules configured
- [ ] Outbound rules configured

### 8. Check Instance Launch

In AWS Console → EC2 → Instances:

- [ ] Django instance running (t3.micro)
- [ ] Nagios instance running (t3.small)
- [ ] Both have public/private IPs
- [ ] Both have security groups attached
- [ ] Both have monitoring enabled

---

## Troubleshooting During Deployment

### If Terraform Job Fails

```bash
# Check Terraform state
cd terraform
terraform state list

# Review error logs
terraform plan -var-file=terraform.tfvars -var-file=monitoring.tfvars

# Cleanup if needed
terraform destroy -auto-approve
```

### If Ansible Job Fails

1. Check Ansible output in GitHub Actions
2. SSH to affected instance
3. Verify system configuration
4. Check security group rules
5. Verify network connectivity

### If Nagios Dashboard Won't Load

```bash
# SSH to Nagios server
ssh ubuntu@<NAGIOS_SERVER_IP>

# Check Apache
sudo systemctl status apache2
sudo apache2ctl configtest

# Check Nagios
sudo systemctl status nagios
sudo /opt/nagios/bin/nagios -v /etc/nagios/nagios.cfg

# View logs
sudo tail -f /var/log/apache2/error.log
sudo tail -f /var/log/nagios/nagios.log
```

### If Services Show "PENDING"

1. Wait 2-3 minutes for first check
2. Verify NRPE connection
3. Check network connectivity
4. Review service definitions

---

## Post-Deployment Configuration

### 1. Change Nagios Admin Password

```bash
# SSH to Nagios server
ssh ubuntu@<NAGIOS_SERVER_IP>

# Change password
sudo htpasswd -c /opt/nagios/etc/htpasswd.users nagiosadmin
```

### 2. Configure Email Alerts

Edit `/etc/nagios/objects/contacts.cfg`:

```bash
sudo nano /etc/nagios/objects/contacts.cfg

# Update email address in contact definition
# Then reload
sudo systemctl reload nagios
```

### 3. Adjust Alert Thresholds

Edit `/etc/nagios/objects/django_app_services.cfg`:

```bash
sudo nano /etc/nagios/objects/django_app_services.cfg

# Modify thresholds as needed
# Then validate and reload
sudo /opt/nagios/bin/nagios -v /etc/nagios/nagios.cfg
sudo systemctl reload nagios
```

### 4. Add More Monitoring Targets

1. Create new host definition in `/etc/nagios/objects/`
2. Add service checks
3. Install NRPE agent on target
4. Update Nagios configuration
5. Reload Nagios

---

## Ongoing Maintenance

### Daily Tasks
- [ ] Check Nagios dashboard for alerts
- [ ] Review alert emails
- [ ] Verify all services are "OK"

### Weekly Tasks
- [ ] Review performance metrics
- [ ] Check disk space on Nagios server
- [ ] Verify NRPE connectivity
- [ ] Check log file sizes

### Monthly Tasks
- [ ] Analyze trends and capacity
- [ ] Update alert thresholds if needed
- [ ] Review security settings
- [ ] Backup Nagios configuration

### Quarterly Tasks
- [ ] Update Nagios Core and plugins
- [ ] Security audit
- [ ] Performance optimization
- [ ] Plan infrastructure scaling

---

## Emergency Procedures

### If Nagios Goes Down

```bash
# Check status
sudo systemctl status nagios

# Restart service
sudo systemctl restart nagios

# Force full restart
sudo systemctl stop nagios
sleep 5
sudo systemctl start nagios

# Verify
sudo systemctl status nagios
```

### If NRPE Agent Fails

```bash
# On Django server
sudo systemctl status nrpe
sudo systemctl restart nrpe

# Test from Nagios
/opt/nagios/libexec/check_nrpe -H <DJANGO_IP> -c check_load
```

### If Alerts Stop

```bash
# Check mail service
sudo systemctl status postfix

# Verify SMTP configuration
sudo postfix status

# Test mail delivery
echo "Test email" | mail -s "Test" your-email@example.com
```

### If EC2 Instances Fail

1. Check AWS Console for instance status
2. Review system logs
3. Check security group rules
4. Verify network connectivity
5. Consider instance reboot
6. Re-run Terraform/Ansible if needed

---

## Success Criteria

✅ **Deployment is complete when:**

- [ ] All GitHub Actions jobs passed
- [ ] Nagios dashboard accessible
- [ ] All 11 service checks showing "OK"
- [ ] Email alerts working
- [ ] Slack alerts working (if configured)
- [ ] Django application responding
- [ ] NRPE agents communicating
- [ ] No error messages in logs
- [ ] Security groups properly configured
- [ ] All instances healthy in AWS

✅ **Monitoring is working when:**

- [ ] Dashboard updates every 5-10 minutes
- [ ] Historical data is collecting
- [ ] Alerts trigger on thresholds
- [ ] Recovery notifications sent
- [ ] Performance data is available
- [ ] Trends can be analyzed

---

## Documentation References

After deployment, review these docs:

1. **Quick Start**: `MONITORING_QUICKSTART.md`
2. **Setup Guide**: `MONITORING_SETUP.md`
3. **Implementation**: `NAGIOS_IMPLEMENTATION_GUIDE.md`
4. **Summary**: `DEPLOYMENT_SUMMARY.md`
5. **This Checklist**: `DEPLOYMENT_CHECKLIST.md`

---

## Support & Help

### If You Get Stuck

1. **Check Documentation**: All docs are comprehensive
2. **Review Logs**: Nagios and system logs are detailed
3. **AWS Console**: Check instance and security status
4. **GitHub Actions**: Review workflow output
5. **Nagios Dashboard**: Check service details
6. **SSH to servers**: Investigate directly if needed

### Quick Commands

```bash
# Get Terraform outputs
terraform -chdir=terraform output

# SSH to Nagios
ssh -i ~/.ssh/id_rsa ubuntu@<NAGIOS_IP>

# SSH to Django
ssh -i ~/.ssh/id_rsa ubuntu@<DJANGO_IP>

# View Nagios logs
ssh -i ~/.ssh/id_rsa ubuntu@<NAGIOS_IP> sudo tail -f /var/log/nagios/nagios.log

# Check NRPE
/opt/nagios/libexec/check_nrpe -H <DJANGO_IP> -c check_load

# Restart Nagios
ssh -i ~/.ssh/id_rsa ubuntu@<NAGIOS_IP> sudo systemctl restart nagios
```

---

## Completion Sign-Off

Once all checkboxes are completed:

```
✅ Date Deployed: ___________________
✅ Deployed By: ___________________
✅ Status: PRODUCTION READY
✅ Dashboard URL: http://___________________/nagios
✅ Contact: ___________________
✅ Next Review: ___________________
```

---

## Notes

```
Additional Notes:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

**Congratulations! Your monitoring is now live and protecting your Django application 24/7!** 🎉

For questions, refer to the comprehensive documentation files or contact your DevOps team.
