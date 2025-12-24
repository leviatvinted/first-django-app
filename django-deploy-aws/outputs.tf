# EC2 Outputs
output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance (Elastic IP)"
  value       = aws_eip.app_server.public_ip
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "ec2_instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.app_server.instance_state
}

# RDS Outputs
output "rds_endpoint" {
  description = "Connection endpoint for the RDS PostgreSQL database"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "Hostname of the RDS instance (without port)"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Port of the RDS PostgreSQL database"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "Name of the PostgreSQL database"
  value       = aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "Master username for the RDS database"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

# Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

# Connection Strings
output "ssh_connection_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ubuntu@${aws_eip.app_server.public_ip}"
}

output "database_url" {
  description = "PostgreSQL connection URL for Django DATABASE_URL"
  value       = "postgresql://${aws_db_instance.postgres.username}:${var.db_password}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
  sensitive   = true
}

# Summary
output "deployment_summary" {
  description = "Quick reference for deployment information"
  value = {
    web_url           = "http://${aws_eip.app_server.public_ip}"
    ssh_command       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ubuntu@${aws_eip.app_server.public_ip}"
    ansible_inventory = "${path.module}/ansible/hosts.ini"
    db_host           = aws_db_instance.postgres.address
    db_port           = aws_db_instance.postgres.port
    db_name           = aws_db_instance.postgres.db_name
  }
}
