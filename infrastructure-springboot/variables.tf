variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "springboot-app"
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
  default     = 8080
}

variable "container_cpu" {
  description = "CPU units for Fargate task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
}

variable "container_memory" {
  description = "Memory for Fargate task in MB"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for auto-scaling"
  type        = number
  default     = 10
}

variable "domain_name" {
  description = "Domain name for ACM certificate (optional)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of existing ACM certificate (optional, will create if not provided)"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "SpringBoot-ECS"
    ManagedBy   = "Terraform"
  }
}

# RDS Variables
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "spring-boot-db"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "spring"
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

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "allowed_ip_cidr" {
  description = "CIDR block for allowed IP to access RDS (e.g., 202.59.13.57/32)"
  type        = string
  default     = "0.0.0.0/0"
}

