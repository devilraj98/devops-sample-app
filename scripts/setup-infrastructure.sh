#!/bin/bash

set -e

echo "Initializing Terraform..."
cd terraform
terraform init

echo "Planning infrastructure..."
terraform plan

echo "Applying infrastructure..."
terraform apply -auto-approve

echo "Getting ECR repository URL..."
ECR_REPO=$(terraform output -raw ecr_repository_url)

echo "Building and pushing initial image..."
cd ..
docker build -t devops-sample-app:latest .
docker tag devops-sample-app:latest ${ECR_REPO}:latest

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ECR_REPO}
docker push ${ECR_REPO}:latest

echo "Infrastructure setup completed!"
echo "ECR Repository: ${ECR_REPO}"