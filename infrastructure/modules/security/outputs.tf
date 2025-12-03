output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

output "bitbucket_user_name" {
  description = "Name of the Bitbucket IAM user"
  value       = aws_iam_user.bitbucket.name
}

output "bitbucket_access_key_id" {
  description = "Access Key ID for Bitbucket (store securely)"
  value       = aws_iam_access_key.bitbucket.id
  sensitive   = true
}

output "bitbucket_secret_access_key" {
  description = "Secret Access Key for Bitbucket (store securely)"
  value       = aws_iam_access_key.bitbucket.secret
  sensitive   = true
}

