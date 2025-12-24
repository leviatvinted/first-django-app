variable "project_name" {
  description = "Project name for resource tagging and identification."
  type        = string
  default     = "blog-app"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for resources."
  type        = string
  default     = "eu-north-1"
}

variable "instance_name" {
  description = "Value of the EC2 instance's Name tag."
  type        = string
  default     = "blog-web-server"
}

variable "instance_type" {
  description = "The EC2 instance's type."
  type        = string
  default     = "t3.micro"
}

variable "rds_instance_type" {
  description = "The RDS instance's type (db.t3.micro for free tier)."
  type        = string
  default     = "db.t3.micro"
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair in AWS (must exist in your AWS account)."
  type        = string
  default     = "django-key"
}

variable "db_name" {
  description = "PostgreSQL database name."
  type        = string
  default     = "blogdb"
  sensitive   = false
}

variable "db_username" {
  description = "PostgreSQL database username."
  type        = string
  default     = "bloguser"
  sensitive   = false
}

variable "db_password" {
  description = "PostgreSQL database password (must be 8+ chars, alphanumeric + special chars)."
  type        = string
  sensitive   = true
  # No default - user must provide this
}

variable "tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default = {
    Project     = "blog-app"
    Environment = "dev"
    ManagedBy   = "terraform"
    CreatedAt   = "2025-12-23"
  }
}
