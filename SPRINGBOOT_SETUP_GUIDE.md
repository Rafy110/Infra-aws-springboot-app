# Spring Boot ECS Deployment Setup Guide

This guide will help you set up and deploy your Spring Boot application to AWS ECS Fargate using Terraform and GitHub Actions.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [AWS Configuration](#aws-configuration)
3. [Terraform Setup](#terraform-setup)
4. [GitHub Actions Setup](#github-actions-setup)
5. [Deployment](#deployment)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### 1. Install Required Tools
- **Terraform** (>= 1.5.0): [Download](https://www.terraform.io/downloads)
- **AWS CLI**: [Install](https://aws.amazon.com/cli/)
- **Docker**: [Install](https://www.docker.com/get-started)
- **Java 17** and **Maven**: For building the Spring Boot application

### 2. Verify Installations
```powershell
terraform version
aws --version
docker --version
java -version
mvn -version
```

## AWS Configuration

### 1. Configure AWS CLI
```powershell
aws configure
```
Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `us-east-1`
- Default output format: `json`

### 2. Create IAM User for Terraform
1. Go to AWS Console → IAM → Users → Create User
2. Name: `terraform-user`
3. Attach policies:
   - `AdministratorAccess` (for initial setup, restrict later)
4. Create Access Key and save credentials securely

### 3. Create IAM User for GitHub Actions
The Terraform will create a GitHub Actions user automatically, but you can also create it manually:

1. Go to AWS Console → IAM → Users → Create User
2. Name: `springboot-app-dev-github-user` (or `springboot-app-prod-github-user`)
3. Attach policies:
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonECS_FullAccess`
   - Custom policy for ECR and ECS operations

## Terraform Setup

### 1. Navigate to Environment Directory
```powershell
cd infrastructure-springboot/environments/dev
```

### 2. Initialize Terraform
```powershell
terraform init
```

### 3. Review Configuration
Edit `terraform.tfvars` if needed:
```hcl
aws_region      = "us-east-1"
app_name        = "springboot-app"
container_port  = 8080
container_cpu   = 512
container_memory = 1024
desired_count   = 2
min_capacity    = 1
max_capacity    = 10
vpc_cidr        = "10.1.0.0/16"

# Database Configuration
db_name          = "spring-boot-db"
db_username      = "spring"
db_password      = "spring!2022"
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
```

### 4. Plan Infrastructure
```powershell
terraform plan
```

### 5. Apply Infrastructure
```powershell
terraform apply
```
Type `yes` when prompted.

### 6. Save Outputs
After successful deployment, note the outputs:
- `alb_dns_name`: Your application URL
- `ecr_repository_url`: ECR repository URL
- `ecs_cluster_name`: ECS cluster name
- `ecs_service_name`: ECS service name
- `db_endpoint`: RDS database endpoint

### 7. Get GitHub Actions Credentials
```powershell
terraform output github_access_key_id
terraform output github_secret_access_key
```
**Save these credentials securely** - you'll need them for GitHub Actions.

## GitHub Actions Setup

### 1. Get GitHub Actions IAM Credentials
After running `terraform apply`, get the credentials:
```powershell
cd infrastructure-springboot/environments/dev
terraform output github_access_key_id
terraform output github_secret_access_key
```

### 2. Configure GitHub Secrets
1. Go to your GitHub repository
2. Settings → Secrets and variables → Actions
3. Add the following secrets:

#### For Dev Environment:
- `AWS_ACCESS_KEY_ID`: Value from `terraform output github_access_key_id`
- `AWS_SECRET_ACCESS_KEY`: Value from `terraform output github_secret_access_key`

#### For Prod Environment:
- Repeat the same steps in `infrastructure-springboot/environments/prod`
- Use different secrets or the same user (depending on your setup)

### 3. Configure GitHub Environments
1. Go to Settings → Environments
2. Create `dev` environment
3. Create `prod` environment
4. (Optional) Add protection rules for production

## Deployment

### 1. Build and Test Locally
```powershell
cd demo
mvn clean package
java -jar target/demo-0.0.1-SNAPSHOT.jar
```
Visit `http://localhost:8080` to verify the application works.

### 2. Build Docker Image Locally (Optional)
```powershell
docker build -t springboot-app:latest .
docker run -p 8080:8080 springboot-app:latest
```

### 3. Deploy via GitHub Actions
1. Push code to `develop` branch → Deploys to **dev** environment
2. Push code to `main` branch → Deploys to **prod** environment

The pipeline will:
- Build the Spring Boot application
- Build Docker image
- Push to ECR
- Deploy to ECS

### 4. Manual Deployment (Alternative)
If you want to deploy manually:

```powershell
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REPOSITORY_URL>

# Build and push
cd demo
docker build -t <ECR_REPOSITORY_URL>:latest .
docker push <ECR_REPOSITORY_URL>:latest

# Force ECS deployment
aws ecs update-service \
  --cluster springboot-app-dev-cluster \
  --service springboot-app-dev-service \
  --force-new-deployment \
  --region us-east-1
```

## Infrastructure Overview

### Architecture
- **VPC**: Isolated network (10.1.0.0/16 for dev, 10.2.0.0/16 for prod)
- **Public Subnets**: ALB and RDS
- **Private Subnets**: ECS tasks
- **ALB**: Application Load Balancer with health checks
- **ECS Fargate**: Container orchestration
- **RDS MySQL**: Database in public subnet
- **ECR**: Docker image registry
- **Secrets Manager**: Database credentials

### Key Differences from Next.js Infrastructure
1. **RDS in Public Subnets**: Direct access without bastion host
2. **No Bastion Host**: Removed for simplicity
3. **Spring Boot Specific**: Port 8080, Actuator health checks
4. **GitHub Actions**: Instead of Bitbucket Pipelines
5. **Separate VPC**: Different CIDR blocks to avoid conflicts

## Troubleshooting

### 1. Terraform Errors
```powershell
# If you get module errors
terraform init -upgrade

# If state is locked
terraform force-unlock <LOCK_ID>
```

### 2. ECS Tasks Not Starting
```powershell
# Check ECS service events
aws ecs describe-services \
  --cluster springboot-app-dev-cluster \
  --services springboot-app-dev-service \
  --region us-east-1

# Check CloudWatch logs
aws logs tail /ecs/springboot-app-dev --follow
```

### 3. Database Connection Issues
```powershell
# Verify RDS is accessible
aws rds describe-db-instances \
  --db-instance-identifier springboot-app-dev-db \
  --region us-east-1

# Check security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=springboot-app-dev-rds-sg" \
  --region us-east-1
```

### 4. Health Check Failures
- Verify Spring Boot Actuator is included in `pom.xml`
- Check `/actuator/health` endpoint is accessible
- Verify port matches in ALB target group and container

### 5. GitHub Actions Pipeline Failures
- Verify AWS credentials are set correctly in GitHub Secrets
- Check ECR repository names match in workflow file
- Verify ECS cluster and service names are correct

## Common Commands

### View ECS Service Status
```powershell
aws ecs describe-services \
  --cluster springboot-app-dev-cluster \
  --services springboot-app-dev-service \
  --region us-east-1
```

### View ECS Task Logs
```powershell
aws logs tail /ecs/springboot-app-dev --follow
```

### Connect to RDS Database
```powershell
# From your local machine (RDS is in public subnet)
mysql -h <DB_ENDPOINT> -u spring -p
# Password: spring!2022
```

### Update ECS Service
```powershell
aws ecs update-service \
  --cluster springboot-app-dev-cluster \
  --service springboot-app-dev-service \
  --force-new-deployment \
  --region us-east-1
```

## Next Steps

1. **Add Domain and SSL**: Update `domain_name` and `certificate_arn` in `terraform.tfvars`
2. **Enable Blue/Green Deployment**: Add CodeDeploy configuration for true Blue/Green
3. **Set up Monitoring**: Configure CloudWatch alarms and dashboards
4. **Add CI/CD Tests**: Add unit and integration tests to GitHub Actions
5. **Secure RDS**: Restrict RDS security group to specific IPs instead of 0.0.0.0/0

## Support

For issues or questions:
1. Check CloudWatch logs
2. Review ECS service events
3. Verify security group rules
4. Check Terraform state: `terraform state list`

