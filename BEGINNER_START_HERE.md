image: node:18-alpine

definitions:
  steps:
    - step: &build-and-test
        name: Build and Test
        caches:
          - node
        script:
          - cd app
          - npm ci
          - npm run build
          - npm run lint || true
          - echo "✅ Build successful"

    # DEV ENVIRONMENT STEPS
    - step: &build-and-push-dev
        name: Build and Push Docker Image (Dev)
        services:
          - docker
        script:
          - |
            # Install AWS CLI v2
            apk add --no-cache aws-cli
            
            # Configure AWS CLI for DEV
            aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
            aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
            aws configure set region $AWS_REGION
            
            # HARDCODED ECR URL for DEV
            ECR_REGISTRY="588945689572.dkr.ecr.us-east-1.amazonaws.com"
            REPO_NAME="nextjs-app-dev"
            
            # Login to ECR
            echo "🔐 Logging into DEV ECR..."
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
            
            # Build Docker image
            echo "🏗️ Building Docker image for DEV..."
            cd app
            docker build -t $REPO_NAME:$BITBUCKET_COMMIT .
            
            # Tag image
            docker tag $REPO_NAME:$BITBUCKET_COMMIT $ECR_REGISTRY/$REPO_NAME:$BITBUCKET_COMMIT
            docker tag $REPO_NAME:$BITBUCKET_COMMIT $ECR_REGISTRY/$REPO_NAME:latest
            
            # Push to ECR
            echo "📤 Pushing to DEV ECR..."
            docker push $ECR_REGISTRY/$REPO_NAME:$BITBUCKET_COMMIT
            docker push $ECR_REGISTRY/$REPO_NAME:latest
            
            echo "✅ Image pushed to DEV ECR: $ECR_REGISTRY/$REPO_NAME:latest"

    - step: &deploy-dev
        name: Deploy to ECS (Dev)
        script:
          - |
            # Install AWS CLI v2
            apk add --no-cache aws-cli
            
            # Configure AWS CLI for DEV
            aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
            aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
            aws configure set region $AWS_REGION
            
            # ECS service details for DEV
            CLUSTER_NAME="nextjs-app-dev-cluster"
            SERVICE_NAME="nextjs-app-dev-service"
            
            echo "🔄 Updating DEV ECS service..."
            aws ecs update-service \
              --cluster $CLUSTER_NAME \
              --service $SERVICE_NAME \
              --force-new-deployment \
              --region $AWS_REGION
            
            echo "⏳ Waiting for DEV service to stabilize..."
            aws ecs wait services-stable \
              --cluster $CLUSTER_NAME \
              --services $SERVICE_NAME \
              --region $AWS_REGION
            
            echo "✅ DEV Deployment completed!"
            
            # Get DEV ALB DNS
            ALB_DNS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'nextjs-app-dev-alb')].DNSName" --output text 2>/dev/null || echo "Check AWS Console for DEV ALB URL")
            echo "🌐 DEV App URL: http://$ALB_DNS"

    # PROD ENVIRONMENT STEPS
    - step: &build-and-push-prod
        name: Build and Push Docker Image (Prod)
        services:
          - docker
        script:
          - |
            # Install AWS CLI v2
            apk add --no-cache aws-cli
            
            # Configure AWS CLI for PROD
            aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID_PROD
            aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY_PROD
            aws configure set region $AWS_REGION_PROD
            
            # HARDCODED ECR URL for PROD
            ECR_REGISTRY="588945689572.dkr.ecr.us-east-1.amazonaws.com"
            REPO_NAME="nextjs-app-prod"
            
            # Login to ECR
            echo "🔐 Logging into PROD ECR..."
            aws ecr get-login-password --region $AWS_REGION_PROD | docker login --username AWS --password-stdin $ECR_REGISTRY
            
            # Build Docker image
            echo "🏗️ Building Docker image for PROD..."
            cd app
            docker build -t $REPO_NAME:$BITBUCKET_COMMIT .
            
            # Tag image
            docker tag $REPO_NAME:$BITBUCKET_COMMIT $ECR_REGISTRY/$REPO_NAME:$BITBUCKET_COMMIT
            docker tag $REPO_NAME:$BITBUCKET_COMMIT $ECR_REGISTRY/$REPO_NAME:latest
            
            # Push to ECR
            echo "📤 Pushing to PROD ECR..."
            docker push $ECR_REGISTRY/$REPO_NAME:$BITBUCKET_COMMIT
            docker push $ECR_REGISTRY/$REPO_NAME:latest
            
            echo "✅ Image pushed to PROD ECR: $ECR_REGISTRY/$REPO_NAME:latest"

    - step: &deploy-prod
        name: Deploy to ECS (Prod)
        deployment: production
        script:
          - |
            # Install AWS CLI v2
            apk add --no-cache aws-cli
            
            # Configure AWS CLI for PROD
            aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID_PROD
            aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY_PROD
            aws configure set region $AWS_REGION_PROD
            
            # ECS service details for PROD
            CLUSTER_NAME="nextjs-app-prod-cluster"
            SERVICE_NAME="nextjs-app-prod-service"
            
            echo "🔄 Updating PROD ECS service..."
            aws ecs update-service \
              --cluster $CLUSTER_NAME \
              --service $SERVICE_NAME \
              --force-new-deployment \
              --region $AWS_REGION_PROD
            
            echo "⏳ Waiting for PROD service to stabilize..."
            aws ecs wait services-stable \
              --cluster $CLUSTER_NAME \
              --services $SERVICE_NAME \
              --region $AWS_REGION_PROD
            
            echo "✅ PROD Deployment completed!"
            
            # Get PROD ALB DNS
            ALB_DNS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'nextjs-app-prod-alb')].DNSName" --output text 2>/dev/null || echo "Check AWS Console for PROD ALB URL")
            echo "🌐 PROD App URL: http://$ALB_DNS"

pipelines:
  branches:
    # DEV Environment: develop branch
    develop:
      - step: *build-and-test
      - step: *build-and-push-dev
      - step: *deploy-dev

    # PROD Environment: main branch
    main:
      - step: *build-and-test
      - step: *build-and-push-prod
      - step: *deploy-prod

  custom:
    # Manual triggers
    deploy-dev:
      - step: *build-and-push-dev
      - step: *deploy-dev
    
    deploy-prod:
      - step: *build-and-push-prod
      - step: *deploy-prod