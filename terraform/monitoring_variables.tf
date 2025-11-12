# Nagios Monitoring Variables for Terraform
# Configure monitoring settings

variable "nagios_instance_type" {
  description = "EC2 instance type for Nagios server"
  type        = string
  default     = "t3.small"

  validation {
    condition     = can(regex("^t[3-4]\\.", var.nagios_instance_type))
    error_message = "Nagios instance type must be t3 or t4 family for cost-effectiveness."
  }
}

variable "nagios_root_volume_size" {
  description = "Root volume size for Nagios server in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.nagios_root_volume_size >= 20 && var.nagios_root_volume_size <= 100
    error_message = "Nagios root volume size must be between 20 and 100 GB."
  }
}

variable "nagios_admin_username" {
  description = "Nagios web interface admin username"
  type        = string
  default     = "nagiosadmin"
  sensitive   = true
}

variable "nagios_admin_password" {
  description = "Nagios web interface admin password"
  type        = string
  sensitive   = true
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for Nagios alerts"
  type        = string
  default     = ""
  sensitive   = true
}

variable "nagios_email_alerts" {
  description = "Email address for Nagios alerts"
  type        = string
  default     = ""
}

variable "enable_nagios_monitoring" {
  description = "Enable Nagios monitoring deployment"
  type        = bool
  default     = true
}

variable "nagios_core_version" {
  description = "Nagios Core version to install"
  type        = string
  default     = "4.4.11"
}

variable "nagios_plugins_version" {
  description = "Nagios Plugins version to install"
  type        = string
  default     = "2.4.6"
}

variable "nrpe_version" {
  description = "NRPE (Nagios Remote Plugin Executor) version"
  type        = string
  default     = "4.1.1"
}
