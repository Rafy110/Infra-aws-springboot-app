# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.app_name}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.app_name}-${var.environment}-ecs-task-execution-role"
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (for application to access AWS services)
resource "aws_iam_role" "ecs_task" {
  name = "${var.app_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.app_name}-${var.environment}-ecs-task-role"
  }
}

# IAM Role for Bitbucket Pipelines (for CI/CD)
resource "aws_iam_user" "bitbucket" {
  name = "${var.app_name}-${var.environment}-bitbucket-user"
  path = "/"
}

# Policy for Bitbucket to push to ECR and update ECS
resource "aws_iam_user_policy" "bitbucket" {
  name = "${var.app_name}-${var.environment}-bitbucket-policy"
  user = aws_iam_user.bitbucket.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_task_execution.arn,
          aws_iam_role.ecs_task.arn
        ]
      }
    ]
  })
}

# Create access keys for Bitbucket (output will be shown in terraform output)
resource "aws_iam_access_key" "bitbucket" {
  user = aws_iam_user.bitbucket.name
}

# SSM Parameter Store - Store Bitbucket credentials securely
resource "aws_ssm_parameter" "bitbucket_access_key" {
  name        = "/${var.app_name}/${var.environment}/bitbucket/aws_access_key_id"
  description = "AWS Access Key ID for Bitbucket Pipelines"
  type        = "SecureString"
  value       = aws_iam_access_key.bitbucket.id

  tags = {
    Name = "${var.app_name}-${var.environment}-bitbucket-access-key"
  }
}

resource "aws_ssm_parameter" "bitbucket_secret_key" {
  name        = "/${var.app_name}/${var.environment}/bitbucket/aws_secret_access_key"
  description = "AWS Secret Access Key for Bitbucket Pipelines"
  type        = "SecureString"
  value       = aws_iam_access_key.bitbucket.secret

  tags = {
    Name = "${var.app_name}-${var.environment}-bitbucket-secret-key"
  }
}

