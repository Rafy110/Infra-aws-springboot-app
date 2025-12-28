# DB Subnet Group (RDS needs subnets in at least 2 AZs)
# Using public subnets for RDS access
resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.public_subnet_ids

  tags = {
    Name = "${var.app_name}-${var.environment}-db-subnet-group"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.app_name}-${var.environment}-rds-sg"
  description = "Security group for RDS MySQL database"
  vpc_id      = var.vpc_id

  # Allow MySQL (port 3306) from ECS tasks only
  ingress {
    description     = "MySQL from ECS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  # Allow MySQL from specific IP only (restricted access)
  ingress {
    description = "MySQL from authorized IP"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-rds-sg"
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "main" {
  identifier = "${var.app_name}-${var.environment}-db"

  # Engine configuration
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 3306

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_type         = "gp3"
  storage_encrypted    = true

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true  # RDS in public subnet for direct access

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  # High availability (Multi-AZ for prod, single AZ for dev)
  multi_az = var.environment == "prod" ? true : false

  # Deletion protection (only for prod)
  deletion_protection = var.environment == "prod" ? true : false
  skip_final_snapshot = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment == "prod" ? "${var.app_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  # Performance insights
  performance_insights_enabled = false

  # Monitoring
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  # Prevent Terraform from changing the master password
  lifecycle {
    ignore_changes = [password]
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-db"
  }
}

# Store database credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.app_name}/${var.environment}/rds/credentials"

  tags = {
    Name = "${var.app_name}-${var.environment}-db-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username     = var.db_username
    password     = var.db_password
    engine       = "mysql"
    host         = aws_db_instance.main.address
    port         = 3306
    dbname       = var.db_name
    dbInstanceIdentifier = aws_db_instance.main.identifier
  })
  
  # Force update when password changes
  lifecycle {
    create_before_destroy = true
  }
}

