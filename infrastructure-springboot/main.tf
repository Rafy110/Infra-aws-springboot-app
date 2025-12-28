terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure backend in your environment-specific main.tf
    # bucket = "your-terraform-state-bucket"
    # key    = "springboot-app/{environment}/terraform.tfstate"
    # region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.tags,
      {
        Environment = var.environment
        Application = var.app_name
      }
    )
  }
}

# Data source to get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  vpc_cidr            = var.vpc_cidr
  availability_zones  = local.azs
  app_name            = var.app_name
  environment         = var.environment
  container_port      = var.container_port
  tags                = var.tags
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  app_name    = var.app_name
  environment = var.environment
  tags        = var.tags
}

# Security Module (IAM roles)
module "security" {
  source = "./modules/security"

  app_name    = var.app_name
  environment = var.environment
  tags        = var.tags
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  app_name         = var.app_name
  environment      = var.environment
  vpc_id           = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  alb_sg_id        = module.networking.alb_security_group_id
  container_port   = var.container_port
  domain_name      = var.domain_name
  certificate_arn  = var.certificate_arn
  tags             = var.tags
}

# RDS Module (in public subnets)
module "rds" {
  source = "./modules/rds"

  app_name              = var.app_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  ecs_security_group_id = module.networking.ecs_security_group_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  db_instance_class     = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  allowed_ip_cidr       = var.allowed_ip_cidr
  tags                  = var.tags
}

# ECS Module with Blue/Green Deployment
module "ecs" {
  source = "./modules/ecs"

  app_name              = var.app_name
  environment           = var.environment
  container_port        = var.container_port
  container_cpu         = var.container_cpu
  container_memory      = var.container_memory
  desired_count         = var.desired_count
  min_capacity          = var.min_capacity
  max_capacity          = var.max_capacity
  ecr_repository_url    = module.ecr.repository_url
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  ecs_security_group_id  = module.networking.ecs_security_group_id
  target_group_arn      = module.alb.target_group_arn
  blue_target_group_name = module.alb.blue_target_group_name
  green_target_group_name = module.alb.green_target_group_name
  task_execution_role_arn = module.security.task_execution_role_arn
  task_role_arn         = module.security.task_role_arn
  # Database connection info
  db_endpoint           = module.rds.db_endpoint
  db_port               = module.rds.db_port
  db_name               = module.rds.db_name
  db_username           = module.rds.db_username
  db_secret_arn         = module.rds.db_secret_arn
  tags                  = var.tags
}

