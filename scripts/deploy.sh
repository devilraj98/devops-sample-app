#!/bin/bash

set -e

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REPO_NAME="devops-sample-app"
ECS_CLUSTER="devops-cluster"
ECS_SERVICE="devops-service"

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

echo "Building Docker image..."
docker build -t ${ECR_REPO_NAME}:latest .

echo "Tagging image for ECR..."
docker tag ${ECR_REPO_NAME}:latest ${ECR_REPO}:latest

echo "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}

echo "Pushing image to ECR..."
docker push ${ECR_REPO}:latest

echo "Updating ECS service..."
aws ecs update-service \
    --cluster ${ECS_CLUSTER} \
    --service ${ECS_SERVICE} \
    --force-new-deployment \
    --region ${AWS_REGION}

echo "Deployment completed successfully!"