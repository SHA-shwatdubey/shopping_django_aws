output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.django_app.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.django_app.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.django_app.private_ip
}

output "elastic_ip" {
  description = "Elastic IP address (if created)"
  value       = var.use_elastic_ip ? aws_eip.django_app[0].public_ip : null
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.django_app.id
}

output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.django_app.key_name
}

output "ssh_connection_string" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.public_key_path} ubuntu@${var.use_elastic_ip ? aws_eip.django_app[0].public_ip : aws_instance.django_app.public_ip}"
}

# Output for Ansible inventory
output "ansible_inventory" {
  description = "Ansible inventory format for the EC2 instance"
  value = {
    instance_ip   = var.use_elastic_ip ? aws_eip.django_app[0].public_ip : aws_instance.django_app.public_ip
    instance_user = "ubuntu"
    instance_id   = aws_instance.django_app.id
  }
}
