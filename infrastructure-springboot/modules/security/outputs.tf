output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

output "github_user_name" {
  description = "Name of the GitHub Actions IAM user"
  value       = aws_iam_user.github.name
}

output "github_access_key_id" {
  description = "Access Key ID for GitHub Actions (store securely)"
  value       = aws_iam_access_key.github.id
  sensitive   = true
}

output "github_secret_access_key" {
  description = "Secret Access Key for GitHub Actions (store securely)"
  value       = aws_iam_access_key.github.secret
  sensitive   = true
}

