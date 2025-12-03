# Quick Start Guide

## Prerequisites Checklist

- [ ] AWS Account with admin access
- [ ] Terraform >= 1.5.0 installed
- [ ] AWS CLI configured locally
- [ ] Bitbucket repository created
- [ ] Domain name (optional, for HTTPS)

## Step 1: Deploy Infrastructure (Dev)

```bash
cd infrastructure/environments/dev
terraform init
terraform plan
terraform apply
```

**Save these outputs:**
- `alb_dns_name` - Your app URL
- `ecr_repository_url` - Docker registry URL
- `bitbucket_access_key_id` - For Bitbucket variables
- `bitbucket_secret_access_key` - For Bitbucket variables

## Step 2: Configure Bitbucket Variables

1. Go to **Repository Settings** → **Pipelines** → **Repository variables**
2. Add these variables (mark secrets as secured):

**Development:**
- `AWS_ACCESS_KEY_ID` = (from terraform output)
- `AWS_SECRET_ACCESS_KEY` = (from terraform output)
- `AWS_REGION` = `us-east-1`
- `APP_NAME` = `nextjs-app`

**Production (if deploying prod):**
- `AWS_ACCESS_KEY_ID_PROD` = (from prod terraform output)
- `AWS_SECRET_ACCESS_KEY_PROD` = (from prod terraform output)
- `AWS_REGION_PROD` = `us-east-1`

## Step 3: Push Code to Bitbucket

```bash
git add .
git commit -m "Initial commit"
git push origin develop  # For dev deployment
```

## Step 4: Verify Deployment

1. Check Bitbucket Pipelines - should auto-deploy
2. Visit ALB DNS name from terraform output
3. Check `/health` endpoint

## Step 5: Deploy Production (Optional)

```bash
cd infrastructure/environments/prod
# Update terraform.tfvars with your domain
terraform init
terraform apply
```

Then push to `main` branch to deploy to production.

## Troubleshooting

### ECS tasks not starting
- Check CloudWatch logs: `/ecs/nextjs-app-dev`
- Verify security groups allow traffic
- Check task definition logs

### Bitbucket pipeline fails
- Verify AWS credentials are correct
- Check IAM user has required permissions
- Ensure ECR repository exists

### Cannot access application
- Verify ALB DNS name is correct
- Check security groups
- Ensure ECS tasks are running and healthy

