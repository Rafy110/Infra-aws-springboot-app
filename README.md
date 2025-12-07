# Next.js Application on AWS ECS with Terraform

Complete AWS infrastructure setup for deploying a Next.js frontend application on AWS ECS Fargate with automated CI/CD via Bitbucket Pipelines.

## 🏗️ Architecture Overview

```
Internet
   │
   ▼
Application Load Balancer (ALB)
   │ HTTPS (443) / HTTP (80)
   │
   ▼
ECS Fargate Tasks (in Private Subnets)
   │
   ├─── Task 1 (Next.js Container)
   ├─── Task 2 (Next.js Container)
   └─── Auto-scaling based on CPU/Memory
   │
   ▼
ECR Repository (Docker Images)
   │
   └─── Lifecycle Policy (keeps last 20 images)
```

### Infrastructure Components

1. **Networking**
   - VPC with CIDR 10.0.0.0/16
   - 2 Public Subnets (for ALB) across 2 AZs
   - 2 Private Subnets (for ECS) across 2 AZs
   - Internet Gateway (for public subnets)
   - NAT Gateway (for private subnets to access internet)
   - Security Groups (ALB and ECS)

2. **Container Registry**
   - ECR Repository per environment
   - Lifecycle policy (keeps last 20 images)
   - Image scanning enabled

3. **Compute**
   - ECS Fargate Cluster
   - Task Definition with Next.js container
   - ECS Service with desired count
   - Auto-scaling (CPU and Memory based)

4. **Load Balancing**
   - Application Load Balancer (public)
   - Target Group (routes to ECS tasks)
   - HTTP listener (redirects to HTTPS)

5. **Security**
   - IAM Roles (Task Execution, Task Role)
   - IAM User for Bitbucket Pipelines
   - SSM Parameter Store for secrets
   - Security Groups (least privilege)

6. **Monitoring**
   - CloudWatch Log Groups
   - Container Insights enabled
   - Health checks configured


## 🔌 How Components Are Wired Together

- **Public Subnets**: Host the ALB, accessible from the internet
- **Private Subnets**: Host ECS tasks, isolated from direct internet access
- **NAT Gateway**: Allows ECS tasks to pull images from ECR and access AWS services
- **Security Groups**:
  - ALB SG: Allows inbound HTTP (80) and HTTPS (443) from anywhere
  - ECS SG: Allows inbound traffic only from ALB SG on port 3000

### 2. **Load Balancer → ECS Connection**

- ALB listens on ports 80 and 443
- Target Group routes traffic to ECS tasks on port 3000
- Health checks configured at `/health` endpoint
- HTTPS uses ACM certificate (auto-created or provided)

### 3. **ECS Task Definition**

```yaml
Task Definition:
  - Image: ECR Repository URL + Tag
  - CPU: Configurable (256, 512, 1024, etc.)
  - Memory: Configurable (512MB, 1024MB, etc.)
  - Port: 3000
  - Execution Role: Pulls images from ECR, writes to CloudWatch
  - Task Role: Application-level AWS permissions
  - Logs: CloudWatch Logs
  - Health Check: /health endpoint
```

### 4. **CI/CD Pipeline Flow**

```
Bitbucket Push (develop/master branch)
  │
  ├── Build & Test
  │   └── npm ci, npm run build, npm run lint
  │
  ├── Build Docker Image
  │   └── Multi-stage build (deps → builder → runner)
  │
  ├── Push to ECR
  │   └── Tagged with commit hash and 'latest'
  │
  └── Deploy to ECS
      └── Force new deployment → ECS pulls new image → Rolling update
```

### 5. **Auto-Scaling**

```
CloudWatch Metrics (CPU/Memory)
  │
  ├── CPU Utilization > 70% → Scale Out
  ├── Memory Utilization > 80% → Scale Out
  └── Below thresholds → Scale In (after cooldown)
```

- **Scale Out**: Add tasks when CPU > 70% or Memory > 80%
- **Scale In**: Remove tasks when below thresholds (5-minute cooldown)
- **Min/Max Capacity**: Configurable per environment

### 6. **Security & IAM**

```
Bitbucket Pipelines
  │
  └── IAM User (bitbucket-user)
      ├── ECR Permissions (push/pull images)
      ├── ECS Permissions (update service, register task definition)
      └── IAM PassRole (for task execution role)

ECS Tasks
  │
  ├── Task Execution Role
  │   └── ECR pull, CloudWatch logs, SSM parameters
  │
  └── Task Role
      └── Application-level AWS service access
```

## 🚀 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.5.0 installed
3. **AWS CLI** configured
4. **Bitbucket** repository
5. **Node.js** 18+ (for local development)
6. **Docker** (for building images locally)

## 📦 Getting Started

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd Terraform-ECS
```

### 2. Install Application Dependencies

```bash
cd app
npm install
```

### 4. Deploy Infrastructure

#### Development Environment

```bash
cd infrastructure/environments/dev

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Apply infrastructure
terraform apply
```

#### Production Environment

```bash
cd infrastructure/environments/prod

# Update terraform.tfvars with your domain
# domain_name = "example.com"

terraform init
terraform plan
terraform apply
```

### 5. Get Outputs

After deployment, note the outputs:

```bash
terraform output
```

## 🔐 Bitbucket Variables Setup

### Step 1: Get AWS Credentials from Terraform

After deploying infrastructure, get the Bitbucket IAM user credentials:

```bash
cd infrastructure/environments/dev  # or prod
terraform output bitbucket_access_key_id
terraform output bitbucket_secret_access_key
```

**Note**: These are also stored in SSM Parameter Store:
- `/nextjs-app/dev/bitbucket/aws_access_key_id`
- `/nextjs-app/dev/bitbucket/aws_secret_access_key`

### Step 2: Add Variables in Bitbucket

1. Go to your Bitbucket repository
2. Navigate to **Repository Settings** → **Pipelines** → **Repository variables**

3. **Add the following variables:**


#### For Production Environment:

| Variable Name | Value | Secured |
|--------------|-------|---------|
| `AWS_ACCESS_KEY_ID_PROD` | From Terraform output (prod) | ✅ Yes |
| `AWS_SECRET_ACCESS_KEY_PROD` | From Terraform output (prod) | ✅ Yes |
| `AWS_REGION_PROD` | `us-east-1` (or your region) | ❌ No |
| `APP_NAME` | `nextjs-app` | ❌ No |

### Step 3: Using Variables in Pipelines

The `bitbucket-pipelines.yml` uses these variables:

```yaml
# Development
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set region $AWS_REGION

# Production
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID_PROD
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY_PROD
aws configure set region $AWS_REGION_PROD
```

### Step 4: Alternative - Using SSM Parameters

You can also retrieve credentials from SSM Parameter Store in your pipeline:

```yaml
script:
  - |
    # Get credentials from SSM
    AWS_ACCESS_KEY_ID=$(aws ssm get-parameter --name "/nextjs-app/dev/bitbucket/aws_access_key_id" --with-decryption --query 'Parameter.Value' --output text)
    AWS_SECRET_ACCESS_KEY=$(aws ssm get-parameter --name "/nextjs-app/dev/bitbucket/aws_secret_access_key" --with-decryption --query 'Parameter.Value' --output text)
    
    # Configure AWS CLI
    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
```

**Note**: For this approach, you'll need to configure AWS CLI in Bitbucket using a different method (e.g., OIDC or a bootstrap IAM user).

## 🚢 Deployment

### Manual Deployment

1. **Build and push Docker image:**

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build image
cd app
docker build -t nextjs-app:latest .

# Tag and push
docker tag nextjs-app:latest <ecr-repo-url>:latest
docker push <ecr-repo-url>:latest
```

2. **Update ECS Service:**

```bash
aws ecs update-service \
  --cluster nextjs-app-dev-cluster \
  --service nextjs-app-dev-service \
  --force-new-deployment \
  --region us-east-1
```

### Automated Deployment via Bitbucket

1. **Push to `develop` branch** → Auto-deploys to dev environment
2. **Push to `main` branch** → Auto-deploys to prod environment
3. **Manual trigger** → Use custom pipelines: `deploy-dev` or `deploy-prod`

## 🔍 Troubleshooting

### Issue: ECS tasks not starting

**Check:**
- Task definition logs in CloudWatch
- Security group rules (ECS SG should allow traffic from ALB SG)
- IAM roles have correct permissions
- ECR image exists and is accessible

```bash
# Check ECS service events
aws ecs describe-services \
  --cluster nextjs-app-dev-cluster \
  --services nextjs-app-dev-service \
  --region us-east-1

# Check task logs
aws logs tail /ecs/nextjs-app-dev --follow --region us-east-1
```

### Issue: ALB health checks failing

**Check:**
- Health check path is `/health`
- Container port is 3000
- Security groups allow traffic
- Task is running and healthy

```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region us-east-1
```

### Issue: Bitbucket pipeline fails

**Check:**
- AWS credentials are correct
- IAM user has required permissions
- ECR repository exists
- ECS cluster and service exist

```bash
# Test AWS credentials
aws sts get-caller-identity

# Test ECR access
aws ecr describe-repositories --region us-east-1
```

### Issue: Cannot access application

**Check:**
- ALB DNS name is correct
- Security groups allow traffic
- ECS tasks are running
- Target group is healthy

```bash
# Get ALB DNS name
terraform output alb_dns_name

# Check ALB status
aws elbv2 describe-load-balancers --region us-east-1
```

## 📝 Environment Variables

The Next.js application supports these environment variables:

- `NODE_ENV`: Set automatically (production/development)
- `PORT`: Set automatically (3000)
- `NEXT_PUBLIC_ENV`: Public environment variable (set in task definition if needed)

## 🔄 Updating Infrastructure

1. **Modify Terraform files**
2. **Review changes:** `terraform plan`
3. **Apply changes:** `terraform apply`

## 🗑️ Destroying Infrastructure

```bash
cd infrastructure/environments/dev  # or prod
terraform destroy
```

**Warning**: This will delete all resources including ECR images, ECS tasks, and ALB.


