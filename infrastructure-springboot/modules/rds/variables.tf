variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of public subnets for RDS"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID of ECS tasks (to allow database access)"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "spring-boot-db"
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "allowed_ip_cidr" {
  description = "CIDR block for allowed IP to access RDS (e.g., 202.59.13.57/32)"
  type        = string
  default     = "0.0.0.0/0"
}

