# Complete Project Guide - Everything Explained

This document explains every file, what it does, and how everything works together.

---

## 📁 Project Structure Overview

```
Terraform-ECS/
├── app/                          # Next.js Application
│   ├── src/                      # Source code
│   ├── Dockerfile               # Docker build instructions
│   ├── package.json             # Node.js dependencies
│   └── next.config.js           # Next.js configuration
│
├── infrastructure/               # Terraform Infrastructure Code
│   ├── modules/                 # Reusable Terraform modules
│   │   ├── networking/         # VPC, subnets, security groups
│   │   ├── ecr/                 # Docker registry
│   │   ├── ecs/                 # Container orchestration
│   │   ├── alb/                 # Load balancer
│   │   └── security/            # IAM roles and permissions
│   │
│   ├── environments/            # Environment-specific configs
│   │   ├── dev/                 # Development environment
│   │   └── prod/                # Production environment
│   │
│   ├── main.tf                  # Root module - wires everything together
│   ├── variables.tf             # Input variables
│   └── outputs.tf               # Output values
│
├── bitbucket-pipelines.yml      # CI/CD Pipeline configuration
└── COMPLETE_GUIDE.md            # This file
```

---

## 🐳 Dockerfile Explained

**Location:** `app/Dockerfile`

### What It Does:
Builds a production-ready Docker image for your Next.js application.

### How It Works:

```dockerfile
# Stage 1: Build
FROM node:18-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci                                    # Install dependencies
COPY . .                                      # Copy source code
RUN npm run build                             # Build Next.js app

# Stage 2: Production Runtime
FROM node:18-alpine AS runner
WORKDIR /app
COPY --from=build /app/.next/standalone ./    # Copy built app
COPY --from=build /app/.next/static ./.next/static  # Copy static files
EXPOSE 3000
CMD ["node", "server.js"]                     # Start the app
```

### Key Points:
- **Multi-stage build**: Reduces final image size (only includes runtime files)
- **Standalone mode**: Next.js creates a minimal server.js file
- **Alpine Linux**: Smaller base image = faster deployments
- **Port 3000**: Where your app listens
- **Health check**: Built-in endpoint at `/health`

### Build Command:
```bash
docker build -t nextjs-app:local .
```

### Run Command:
```bash
docker run -p 3000:3000 nextjs-app:local
```

---

## 🔄 Bitbucket Pipeline Explained

**Location:** `bitbucket-pipelines.yml`

### What It Does:
Automatically builds, tests, and deploys your application when you push code.

### Pipeline Flow:

```
Push to 'develop' branch
    ↓
1. Build & Test
   - Install dependencies (npm install)
   - Build Next.js app (npm run build)
   - Run linter (npm run lint)
    ↓
2. Build & Push Docker Image
   - Build Docker image
   - Tag with commit hash and 'latest'
   - Push to AWS ECR (Docker registry)
    ↓
3. Deploy to ECS
   - Update ECS service
   - ECS pulls new image from ECR
   - New containers start
   - Old containers stop
    ↓
✅ Application deployed!
```

### Step-by-Step Breakdown:

#### Step 1: Build and Test
```yaml
- cd app
- npm install          # Install dependencies
- npm run build        # Build Next.js app
- npm run lint         # Check code quality
```

#### Step 2: Build and Push Docker Image
```yaml
- Configure AWS CLI with credentials
- Login to ECR (Docker registry)
- Build Docker image
- Tag image (commit hash + latest)
- Push to ECR
```

#### Step 3: Deploy to ECS
```yaml
- Update ECS service (force new deployment)
- ECS automatically:
  - Pulls new image from ECR
  - Starts new containers
  - Stops old containers
  - Routes traffic to new containers
```

### Required Bitbucket Variables:
1. `AWS_ACCESS_KEY_ID` - AWS access key (secured)
2. `AWS_SECRET_ACCESS_KEY` - AWS secret key (secured)
3. `AWS_REGION` - AWS region (e.g., `us-east-1`)
4. `APP_NAME` - Application name (e.g., `nextjs-app`)

---

## 🏗️ Terraform Infrastructure Explained

### Root Level Files

#### `infrastructure/main.tf`
**What it does:** Main entry point that wires all modules together.

**Key sections:**
```hcl
# Provider configuration
provider "aws" {
  region = var.aws_region
}

# Module calls - creates all AWS resources
module "networking" { ... }    # Creates VPC, subnets
module "ecr" { ... }            # Creates Docker registry
module "security" { ... }       # Creates IAM roles
module "alb" { ... }            # Creates load balancer
module "ecs" { ... }            # Creates ECS cluster and service
```

#### `infrastructure/variables.tf`
**What it does:** Defines all input variables (like function parameters).

**Key variables:**
- `aws_region` - AWS region to deploy to
- `environment` - dev or prod
- `app_name` - Name of your application
- `container_cpu` - CPU for containers (256, 512, 1024)
- `container_memory` - Memory for containers (512, 1024, 2048)
- `desired_count` - Number of containers to run

#### `infrastructure/outputs.tf`
**What it does:** Returns important values after deployment.

**Key outputs:**
- `alb_dns_name` - Your application URL
- `ecr_repository_url` - Docker registry URL
- `ecs_cluster_name` - ECS cluster name
- `ecs_service_name` - ECS service name

---

### Terraform Modules Explained

#### 1. Networking Module (`modules/networking/`)

**What it creates:**
- **VPC**: Virtual private cloud (your network)
- **Public Subnets**: For load balancer (internet-facing)
- **Private Subnets**: For ECS tasks (isolated)
- **Internet Gateway**: Allows public subnets to access internet
- **NAT Gateway**: Allows private subnets to access internet (for pulling images)
- **Security Groups**: Firewall rules
  - ALB SG: Allows HTTP (80) and HTTPS (443) from anywhere
  - ECS SG: Allows traffic only from ALB on port 3000

**Why:** Isolates your containers from direct internet access for security.

#### 2. ECR Module (`modules/ecr/`)

**What it creates:**
- **ECR Repository**: Docker image storage
- **Lifecycle Policy**: Keeps only last 20 images (saves storage costs)

**Why:** Stores your Docker images so ECS can pull them.

#### 3. Security Module (`modules/security/`)

**What it creates:**
- **ECS Task Execution Role**: Allows ECS to pull images and write logs
- **ECS Task Role**: Permissions for your application
- **Bitbucket IAM User**: User for CI/CD pipeline
- **Access Keys**: Credentials for Bitbucket (stored in SSM)

**Why:** Provides secure access without hardcoding credentials.

#### 4. ALB Module (`modules/alb/`)

**What it creates:**
- **Application Load Balancer**: Distributes traffic to containers
- **Target Group**: Routes traffic to ECS tasks
- **HTTP Listener (port 80)**: Redirects to HTTPS (if certificate exists)
- **HTTPS Listener (port 443)**: Serves traffic with SSL (if certificate exists)
- **Health Check**: Checks `/health` endpoint

**Why:** Provides a single URL, handles SSL, and distributes load.

#### 5. ECS Module (`modules/ecs/`)

**What it creates:**
- **ECS Cluster**: Container orchestration platform
- **Task Definition**: Container configuration (image, CPU, memory, ports)
- **ECS Service**: Manages running containers
- **Auto Scaling**: Scales containers based on CPU/memory usage
- **CloudWatch Logs**: Application logs

**Why:** Runs and manages your containers automatically.

---

### Environment-Specific Files

#### `environments/dev/terraform.tfvars`
**What it does:** Sets variable values for development environment.

**Example:**
```hcl
aws_region      = "us-east-1"
app_name        = "nextjs-app"
container_cpu   = 256              # Lower for dev (saves money)
container_memory = 512             # Lower for dev
desired_count   = 1                # Only 1 container for dev
min_capacity    = 1
max_capacity    = 5
```

#### `environments/dev/main.tf`
**What it does:** Calls the root module with dev-specific settings.

```hcl
module "infrastructure" {
  source = "../../"
  environment = "dev"
  # ... other variables
}
```

#### `environments/dev/outputs.tf`
**What it does:** Outputs important values after deployment.

---

## 🔄 How Everything Works Together

### Deployment Flow:

```
1. Developer pushes code to Bitbucket
   ↓
2. Bitbucket Pipeline triggers
   ↓
3. Pipeline builds Docker image
   ↓
4. Pipeline pushes image to ECR
   ↓
5. Pipeline updates ECS service
   ↓
6. ECS pulls new image from ECR
   ↓
7. ECS starts new containers
   ↓
8. ALB routes traffic to new containers
   ↓
9. Application is live!
```

### Request Flow:

```
User visits ALB URL
   ↓
ALB (Load Balancer)
   ↓
Target Group (routes to healthy containers)
   ↓
ECS Task (your Next.js container)
   ↓
Application responds
```

### Infrastructure Flow:

```
Internet
   ↓
Internet Gateway
   ↓
Public Subnets (ALB)
   ↓
Application Load Balancer
   ↓
Target Group
   ↓
Private Subnets (ECS Tasks)
   ↓
NAT Gateway (for pulling images)
   ↓
ECR (Docker images)
```

---

## 📝 Key Commands

### Terraform Commands:
```bash
# Initialize Terraform
terraform init

# See what will be created
terraform plan

# Create infrastructure
terraform apply

# See outputs (URLs, credentials)
terraform output

# Destroy infrastructure
terraform destroy
```

### Docker Commands:
```bash
# Build image
docker build -t nextjs-app:local .

# Run container
docker run -p 3000:3000 nextjs-app:local

# Test locally
curl http://localhost:3000/health
```

### AWS CLI Commands:
```bash
# Check ECS service status
aws ecs describe-services \
  --cluster nextjs-app-dev-cluster \
  --services nextjs-app-dev-service \
  --region us-east-1

# View logs
aws logs tail /ecs/nextjs-app-dev --follow --region us-east-1

# List ECR images
aws ecr list-images \
  --repository-name nextjs-app-dev \
  --region us-east-1
```

---

## 🔐 Security Explained

### Security Groups (Firewall):
- **ALB Security Group**: Allows HTTP/HTTPS from internet
- **ECS Security Group**: Only allows traffic from ALB (not directly from internet)

### IAM Roles:
- **Task Execution Role**: ECS uses this to pull images and write logs
- **Task Role**: Your application uses this to access AWS services
- **Bitbucket User**: Pipeline uses this to push images and deploy

### Network Isolation:
- Containers in private subnets (no direct internet access)
- Only ALB in public subnets (internet-facing)
- NAT Gateway allows containers to pull images securely

---

## 💰 Cost Optimization

### Development Environment:
- 1 container (desired_count = 1)
- Lower CPU/memory (256 CPU, 512 MB)
- Auto-scaling: 1-5 containers

### Production Environment:
- 2+ containers (desired_count = 2)
- Higher CPU/memory (512 CPU, 1024 MB)
- Auto-scaling: 2-10 containers

### ECR Lifecycle Policy:
- Keeps only last 20 images
- Automatically deletes old images
- Saves storage costs

---

## 🐛 Troubleshooting

### 503 Error:
- **Cause**: No containers running or no image in ECR
- **Fix**: Push code to trigger pipeline, wait for deployment

### Pipeline Fails:
- **Check**: Bitbucket variables are set correctly
- **Check**: AWS credentials have correct permissions
- **Check**: ECR repository exists

### Containers Not Starting:
- **Check**: CloudWatch logs: `/ecs/nextjs-app-dev`
- **Check**: Task definition has correct image URL
- **Check**: Security groups allow traffic

### Can't Access Application:
- **Check**: ALB DNS name is correct
- **Check**: Security groups allow traffic
- **Check**: Containers are running and healthy

---

## 📚 File Summary

| File | Purpose |
|------|---------|
| `Dockerfile` | Builds Docker image |
| `bitbucket-pipelines.yml` | CI/CD automation |
| `main.tf` | Wires all modules together |
| `variables.tf` | Input parameters |
| `outputs.tf` | Return values |
| `terraform.tfvars` | Environment-specific values |
| `modules/networking/` | VPC, subnets, security |
| `modules/ecr/` | Docker registry |
| `modules/ecs/` | Container orchestration |
| `modules/alb/` | Load balancer |
| `modules/security/` | IAM roles and permissions |

---

## ✅ Quick Checklist

Before deploying:
- [ ] AWS CLI configured (`aws configure`)
- [ ] Terraform installed
- [ ] Bitbucket variables set
- [ ] Code pushed to repository

After deploying:
- [ ] Check Terraform outputs
- [ ] Verify ECS service is running
- [ ] Test ALB URL
- [ ] Check CloudWatch logs

---

This guide covers everything in the project. Each file has a specific purpose and works together to create a complete, production-ready deployment pipeline! 🚀

