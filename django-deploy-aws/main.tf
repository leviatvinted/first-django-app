provider "aws" {
  # Configuration options
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = var.project_name
  cidr = "10.0.0.0/16"

  azs             = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = var.tags
}

# Security Group for EC2 Web Server
resource "aws_security_group" "ec2_web" {
  name        = "${var.project_name}-ec2-web-sg"
  description = "Security group for EC2 web server - allows SSH, HTTP, HTTPS"
  vpc_id      = module.vpc.vpc_id

  # SSH access
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ec2-web-sg"
    }
  )
}

# Security Group for RDS PostgreSQL
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL - allows access from EC2 only"
  vpc_id      = module.vpc.vpc_id

  # PostgreSQL access from EC2 security group only
  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_web.id]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-rds-sg"
    }
  )
}

# EC2 Instance for Django Web Application
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.ec2_web.id]
  subnet_id              = module.vpc.public_subnets[0]

  # Basic setup script
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3 python3-pip python3-venv
              echo "EC2 instance initialized" > /tmp/init-complete.txt
              EOF

  tags = merge(
    var.tags,
    {
      Name = var.instance_name
    }
  )

  depends_on = [module.vpc]
}

# Elastic IP for EC2 (static public IP)
resource "aws_eip" "app_server" {
  instance = aws_instance.app_server.id
  domain   = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eip"
    }
  )

  depends_on = [aws_instance.app_server]

  # Generate Ansible inventory file after EIP is assigned
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/ansible
      cat > ${path.module}/ansible/hosts.ini <<EOF
[webservers]
${self.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${var.ssh_key_name}.pem

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
    EOT
  }
}

# DB Subnet Group for RDS (requires 2+ subnets in different AZs)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-subnet-group"
    }
  )
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier     = "${var.project_name}-postgres"
  engine         = "postgres"
  engine_version = "14" # Let AWS pick latest 14.x patch version
  instance_class = var.rds_instance_type

  # Storage configuration (Free Tier: 20 GB)
  allocated_storage     = 20
  max_allocated_storage = 0 # Disable autoscaling for Free Tier
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  # Network & Security
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # High Availability (Disabled for Free Tier)
  multi_az = false

  # Backup configuration
  backup_retention_period = 0
  backup_window           = "03:00-04:00"         # UTC
  maintenance_window      = "mon:04:00-mon:05:00" # UTC

  # Automated backups
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Performance and monitoring
  performance_insights_enabled = false # Not in Free Tier
  monitoring_interval          = 0     # Disabled for Free Tier

  # Deletion protection
  deletion_protection = false # Set to true for production
  skip_final_snapshot = true  # Set to false for production

  # Apply changes immediately (for dev environment)
  apply_immediately = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-postgres"
    }
  )

  depends_on = [aws_db_subnet_group.main]
}
