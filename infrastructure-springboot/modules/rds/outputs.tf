output "db_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "RDS database port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "RDS database username"
  value       = aws_db_instance.main.username
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret for database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "rds_security_group_id" {
  description = "Security group ID of RDS"
  value       = aws_security_group.rds.id
}

