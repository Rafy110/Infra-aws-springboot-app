# Spring Boot ECS Blue/Green Deployment - Complete Setup Guide

This comprehensive guide will walk you through setting up your Spring Boot application with **Blue/Green deployment** on AWS ECS using Terraform and GitHub Actions.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step-by-Step Setup](#step-by-step-setup)
4. [GitHub Configuration](#github-configuration)
5. [Deployment Process](#deployment-process)
6. [Understanding Blue/Green Deployment](#understanding-bluegreen-deployment)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

### What is Blue/Green Deployment?

Blue/Green deployment is a technique that reduces downtime and risk by running two identical production environments called **Blue** and **Green**. 

- **Blue**: Currently serving production traffic
- **Green**: New version being deployed and tested
- **Switch**: Once Green is healthy, traffic switches from Blue to Green
- **Rollback**: If issues occur, traffic can instantly switch back to Blue

### Architecture Components

```
┌─────────────────────────────────────────────────────────┐
│                    Application Load Balancer            │
│                    (Routes traffic to Blue/Green)       │
└────────────────────┬──────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
    ┌───▼───┐                ┌───▼───┐
    │ Blue  │                │ Green │
    │ Target│                │ Target│
    │ Group │                │ Group │
    └───┬───┘                └───┬───┘
        │                         │
    ┌───▼───┐                ┌───▼───┐
    │ ECS   │                │ ECS   │
    │ Tasks │                │ Tasks │
    │ (Old) │                │ (New) │
    └───────┘                └───────┘
```

### Key Features

✅ **Zero Downtime**: Traffic switches instantly between Blue and Green  
✅ **Instant Rollback**: If Green fails, switch back to Blue immediately  
✅ **Health Checks**: Automatic validation before traffic switch  
✅ **Automatic Cleanup**: Old Blue environment terminated after successful deployment  

---

## 📦 Prerequisites

### 1. Required Software

Install the following on your local machine:

```powershell
# Terraform (>= 1.5.0)
terraform version

# AWS CLI
aws --version

# Docker
docker --version

# Java 17 and Maven
java -version
mvn -version

# Git
git --version
```

### 2. AWS Account Setup

#### A. Configure AWS CLI

```powershell
aws configure
```

Enter:
- **AWS Access Key ID**: Your IAM user access key
- **AWS Secret Access Key**: Your IAM user secret key
- **Default region**: `us-east-1`
- **Default output format**: `json`

#### B. Create IAM User for Terraform

1. Go to **AWS Console → IAM → Users → Create User**
2. Name: `terraform-user`
3. Attach policy: `AdministratorAccess` (for initial setup)
4. Create Access Key and **save credentials securely**

#### C. Verify AWS Access

```powershell
aws sts get-caller-identity
```

You should see your account ID and user ARN.

---

## 🚀 Step-by-Step Setup

### Step 1: Clone and Navigate to Project

```powershell
cd C:\Terraform-ECS
```

### Step 2: Configure Terraform Variables

#### For Dev Environment:

Edit `infrastructure-springboot/environments/dev/terraform.tfvars`:

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

# RDS Database Configuration
db_name          = "spring-boot-db"
db_username     = "spring"
db_password      = "spring!2022"
db_instance_class = "db.t3.micro"
db_allocated_storage = 20

# RDS Access - Your IP Only
allowed_ip_cidr = "202.59.13.57/32"

tags = {
  ManagedBy = "Terraform"
  Project   = "SpringBoot-ECS"
}
```

#### For Prod Environment:

Edit `infrastructure-springboot/environments/prod/terraform.tfvars`:

```hcl
aws_region      = "us-east-1"
app_name        = "springboot-app"
container_port  = 8080
container_cpu   = 1024
container_memory = 2048
desired_count   = 2
min_capacity    = 2
max_capacity    = 20
vpc_cidr        = "10.2.0.0/16"

# RDS Database Configuration
db_name          = "spring-boot-db"
db_username      = "spring"
db_password      = "spring!2022"
db_instance_class = "db.t3.small"
db_allocated_storage = 50

# RDS Access - Your IP Only
allowed_ip_cidr = "202.59.13.57/32"

tags = {
  ManagedBy = "Terraform"
  Project   = "SpringBoot-ECS"
}
```

### Step 3: Initialize Terraform

```powershell
cd infrastructure-springboot/environments/dev
terraform init
```

### Step 4: Review Infrastructure Plan

```powershell
terraform plan
```

Review the plan to see what will be created:
- VPC with public/private subnets
- Application Load Balancer
- **Blue and Green Target Groups** (for Blue/Green deployment)
- ECS Cluster and Service
- **CodeDeploy Application and Deployment Group**
- RDS MySQL database
- ECR repository
- IAM roles and policies

### Step 5: Deploy Infrastructure

```powershell
terraform apply
```

Type `yes` when prompted. This will take approximately **15-20 minutes**.

### Step 6: Save Important Outputs

After deployment completes, save these outputs:

```powershell
terraform output
```

**Important outputs to save:**
- `alb_dns_name`: Your application URL
- `ecr_repository_url`: Docker image repository
- `ecs_cluster_name`: ECS cluster name
- `ecs_service_name`: ECS service name
- `db_endpoint`: RDS database endpoint
- `github_access_key_id`: **Save this for GitHub Secrets**
- `github_secret_access_key`: **Save this for GitHub Secrets**

### Step 7: Get GitHub Actions Credentials

```powershell
terraform output github_access_key_id
terraform output github_secret_access_key
```

**⚠️ IMPORTANT**: Save these credentials - you'll need them for GitHub Secrets.

---

## 🔐 GitHub Configuration

### Step 1: Create GitHub Repository

1. Go to **GitHub → New Repository**
2. Name: `your-springboot-app` (or use existing)
3. Make it **Private** (recommended)
4. Don't initialize with README (if you already have code)

### Step 2: Push Your Code

```powershell
cd C:\Terraform-ECS
git init
git add .
git commit -m "Initial commit: Spring Boot ECS Blue/Green setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

### Step 3: Create GitHub Environments

1. Go to your repository → **Settings → Environments**
2. Click **New environment**
3. Name: `dev`
4. Click **New environment** again
5. Name: `prod`
6. (Optional) Add protection rules for `prod`

### Step 4: Configure GitHub Secrets

1. Go to **Settings → Secrets and variables → Actions**
2. Click **New repository secret**

Add these secrets:

#### For Dev Environment:
- **Name**: `AWS_ACCESS_KEY_ID`
  - **Value**: From `terraform output github_access_key_id` (dev environment)
- **Name**: `AWS_SECRET_ACCESS_KEY`
  - **Value**: From `terraform output github_secret_access_key` (dev environment)

#### For Prod Environment:
- **Name**: `AWS_ACCESS_KEY_ID`
  - **Value**: From `terraform output github_access_key_id` (prod environment)
- **Name**: `AWS_SECRET_ACCESS_KEY`
  - **Value**: From `terraform output github_secret_access_key` (prod environment)

**Note**: If using the same IAM user for both environments, use the same credentials.

### Step 5: Verify GitHub Actions Workflow

The workflow file is already created at `.github/workflows/deploy.yml`. It will:
- Build Spring Boot application
- Build Docker image
- Push to ECR
- Create new task definition
- **Trigger Blue/Green deployment via CodeDeploy**

---

## 🚢 Deployment Process

### Automatic Deployment (Recommended)

#### Deploy to Dev:
```powershell
git checkout develop
git add .
git commit -m "Deploy new version"
git push origin develop
```

This triggers:
1. GitHub Actions workflow
2. Builds Docker image
3. Pushes to ECR
4. **CodeDeploy creates Blue/Green deployment**
5. Green environment starts with new version
6. Health checks validate Green
7. Traffic switches from Blue to Green
8. Blue environment terminates

#### Deploy to Prod:
```powershell
git checkout main
git merge develop
git push origin main
```

Same process, but deploys to production environment.

### Manual Deployment (Alternative)

If you need to deploy manually:

```powershell
# 1. Build and push Docker image
cd demo
docker build -t <ECR_REPO_URL>:latest .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REPO_URL>
docker push <ECR_REPO_URL>:latest

# 2. Create new task definition
aws ecs describe-task-definition --task-definition springboot-app-dev --query 'taskDefinition' > task-def.json
# Edit task-def.json to update image
aws ecs register-task-definition --cli-input-json file://task-def.json

# 3. Create CodeDeploy deployment
aws deploy create-deployment \
  --application-name springboot-app-dev-codedeploy \
  --deployment-group-name springboot-app-dev-deployment-group \
  --revision revisionType=AppSpecContent,appSpecContent={content="version: 0.0\nResources:\n  - TargetService:\n      Type: AWS::ECS::Service\n      Properties:\n        TaskDefinition: <NEW_TASK_DEF_ARN>\n        LoadBalancerInfo:\n          ContainerName: springboot-app-dev-container\n          ContainerPort: 8080",contentType=application/x-yaml}
```

---

## 🔄 Understanding Blue/Green Deployment

### How It Works

1. **Initial State**: Blue target group has running tasks, serving traffic
2. **Deployment Triggered**: CodeDeploy creates a deployment
3. **Green Environment Created**: New tasks start in Green target group
4. **Health Checks**: Green tasks must pass health checks
5. **Traffic Switch**: ALB switches traffic from Blue to Green
6. **Validation Period**: Green serves traffic, monitored for issues
7. **Cleanup**: Blue environment terminated after successful deployment

### Blue/Green vs Rolling Update

| Feature | Blue/Green | Rolling Update |
|---------|-----------|----------------|
| Downtime | Zero | Minimal |
| Rollback | Instant | Gradual |
| Resource Usage | 2x during deployment | 1x |
| Risk | Low | Medium |
| Speed | Fast switch | Gradual |

### Monitoring Deployment

```powershell
# Check deployment status
aws deploy get-deployment \
  --deployment-id <DEPLOYMENT_ID> \
  --region us-east-1

# Check ECS service status
aws ecs describe-services \
  --cluster springboot-app-dev-cluster \
  --services springboot-app-dev-service \
  --region us-east-1

# View CloudWatch logs
aws logs tail /ecs/springboot-app-dev --follow
```

---

## 🔧 Troubleshooting

### Issue 1: Terraform Apply Fails

**Error**: `Error creating ECS service: InvalidParameterException`

**Solution**: 
- Ensure CodeDeploy application is created first
- Check that target groups (blue/green) exist
- Verify IAM roles have correct permissions

### Issue 2: Deployment Stuck

**Error**: Deployment in "InProgress" state for too long

**Solution**:
```powershell
# Check deployment status
aws deploy get-deployment --deployment-id <ID>

# Check ECS service events
aws ecs describe-services --cluster <CLUSTER> --services <SERVICE>

# Check CloudWatch logs
aws logs tail /ecs/springboot-app-dev --follow
```

### Issue 3: Health Check Failures

**Error**: Green environment fails health checks

**Solution**:
- Verify `/actuator/health` endpoint is accessible
- Check Spring Boot Actuator is in `pom.xml`
- Verify container port matches (8080)
- Check security group allows traffic from ALB

### Issue 4: RDS Connection Denied

**Error**: `Access denied for user 'spring'@'IP'`

**Solution**:
- Verify your IP is in RDS security group: `202.59.13.57/32`
- Check RDS is publicly accessible
- Verify database credentials in Secrets Manager

### Issue 5: GitHub Actions Fails

**Error**: `AccessDenied: User is not authorized to perform: codedeploy:CreateDeployment`

**Solution**:
- Verify GitHub Secrets are set correctly
- Check IAM user has CodeDeploy permissions
- Ensure CodeDeploy application exists

### Issue 6: Cannot Access Application

**Error**: 503 Service Unavailable

**Solution**:
```powershell
# Check ALB target group health
aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN>

# Check ECS tasks are running
aws ecs list-tasks \
  --cluster springboot-app-dev-cluster \
  --service-name springboot-app-dev-service

# Check task logs
aws logs tail /ecs/springboot-app-dev --follow
```

---

## 📊 Monitoring and Logs

### View Application Logs

```powershell
# Follow logs in real-time
aws logs tail /ecs/springboot-app-dev --follow

# View specific log stream
aws logs get-log-events \
  --log-group-name /ecs/springboot-app-dev \
  --log-stream-name <STREAM_NAME>
```

### Monitor Deployment

```powershell
# List recent deployments
aws deploy list-deployments \
  --application-name springboot-app-dev-codedeploy \
  --deployment-group-name springboot-app-dev-deployment-group

# Get deployment details
aws deploy get-deployment \
  --deployment-id <DEPLOYMENT_ID>
```

### Check ECS Service Status

```powershell
aws ecs describe-services \
  --cluster springboot-app-dev-cluster \
  --services springboot-app-dev-service \
  --query 'services[0].{Status:status,RunningCount:runningCount,DesiredCount:desiredCount,Deployments:deployments}'
```

---

## ✅ Verification Checklist

After setup, verify:

- [ ] Terraform apply completed successfully
- [ ] ECS service is running
- [ ] ALB target groups (blue/green) exist
- [ ] CodeDeploy application created
- [ ] RDS database accessible from your IP
- [ ] GitHub Secrets configured
- [ ] GitHub Actions workflow runs successfully
- [ ] Application accessible via ALB DNS name
- [ ] Blue/Green deployment works

---

## 🎓 Key Concepts Explained

### 1. Target Groups (Blue/Green)

- **Blue Target Group**: Currently serving production traffic
- **Green Target Group**: New version being deployed
- **ALB Listener**: Routes traffic to active target group
- **CodeDeploy**: Manages switching between Blue and Green

### 2. CodeDeploy

- **Application**: Logical grouping of deployments
- **Deployment Group**: Defines where to deploy (ECS service)
- **AppSpec**: Defines deployment configuration
- **Revision**: Version of code/configuration to deploy

### 3. ECS Service with CODE_DEPLOY

- **Deployment Controller**: Set to `CODE_DEPLOY` (not `ECS`)
- **No Load Balancer Block**: CodeDeploy manages target groups
- **Task Definition**: Updated by CodeDeploy during deployment

### 4. RDS Security

- **Public Subnet**: RDS in public subnet for direct access
- **Security Group**: Only allows your IP (`202.59.13.57/32`)
- **ECS Access**: ECS tasks can access via security group rule

---

## 🚨 Important Notes

1. **RDS Access**: Only your IP (`202.59.13.57/32`) can access RDS directly
2. **Blue/Green**: Uses CodeDeploy, NOT rolling updates
3. **Port**: Must be 8080 everywhere (ALB, ECS, Container, Spring Boot)
4. **Health Checks**: Uses `/actuator/health` endpoint
5. **Zero Downtime**: Blue/Green ensures no downtime during deployments

---

## 📞 Support

If you encounter issues:

1. Check CloudWatch logs: `/ecs/springboot-app-{env}`
2. Review ECS service events
3. Verify CodeDeploy deployment status
4. Check security group rules
5. Verify IAM permissions

---

## 🎉 Success!

Your Spring Boot application is now set up with:
- ✅ Blue/Green deployment (zero downtime)
- ✅ Automatic deployments via GitHub Actions
- ✅ Secure RDS access (your IP only)
- ✅ Health checks and monitoring
- ✅ Auto-scaling
- ✅ Production-ready infrastructure

**Next Steps:**
1. Push code to `develop` branch to deploy to dev
2. Merge to `main` branch to deploy to prod
3. Monitor deployments in AWS Console
4. Set up CloudWatch alarms for monitoring

