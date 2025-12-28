output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.infrastructure.alb_dns_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.infrastructure.ecr_repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.infrastructure.ecs_cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.infrastructure.ecs_service_name
}

output "db_endpoint" {
  description = "RDS database endpoint"
  value       = module.infrastructure.db_endpoint
}

