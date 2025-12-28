variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
}

variable "container_cpu" {
  description = "CPU units for Fargate task"
  type        = number
}

variable "container_memory" {
  description = "Memory for Fargate task in MB"
  type        = number
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
}

variable "min_capacity" {
  description = "Minimum number of tasks for auto-scaling"
  type        = number
}

variable "max_capacity" {
  description = "Maximum number of tasks for auto-scaling"
  type        = number
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ID of the ECS security group"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group (for backward compatibility)"
  type        = string
}

variable "blue_target_group_name" {
  description = "Name of the blue target group for Blue/Green deployment"
  type        = string
}

variable "green_target_group_name" {
  description = "Name of the green target group for Blue/Green deployment"
  type        = string
}

variable "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "db_endpoint" {
  description = "RDS database endpoint"
  type        = string
}

variable "db_port" {
  description = "RDS database port"
  type        = number
}

variable "db_name" {
  description = "RDS database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of Secrets Manager secret with database credentials"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

