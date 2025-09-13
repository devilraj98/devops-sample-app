# DevOps CI/CD Pipeline Project

A complete CI/CD pipeline implementation using AWS, Jenkins, and GitHub for a Node.js application.

## Architecture Overview

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   GitHub    │───▶│   Jenkins   │───▶│   AWS ECR   │───▶│   AWS ECS   │
│ Repository  │    │  Pipeline   │    │  Registry   │    │  Fargate    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       │                   │                   │                   ▼
       │                   │                   │           ┌─────────────┐
       │                   │                   │           │ CloudWatch  │
       │                   │                   │           │ Monitoring  │
       │                   │                   │           └─────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Webhook   │    │   Docker    │    │  Terraform  │
│   Trigger   │    │   Build     │    │     IaC     │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Components

### 1. Application Stack
- **Node.js**: Express.js web application
- **Docker**: Containerization
- **Jest**: Unit testing framework

### 2. CI/CD Pipeline
- **GitHub**: Source code repository with webhook triggers
- **Jenkins**: Automated CI/CD pipeline with stages:
  - Build & Test
  - Docker Image Creation
  - Push to ECR
  - Deploy to ECS

### 3. AWS Infrastructure
- **VPC**: Isolated network environment
- **ECR**: Container registry for Docker images
- **ECS Fargate**: Serverless container orchestration
- **CloudWatch**: Monitoring and logging
- **IAM**: Security and access management

### 4. Infrastructure as Code
- **Terraform**: Complete AWS infrastructure provisioning

## Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Docker installed
- Terraform installed
- Jenkins server with required plugins
- Node.js 16+ installed

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd devops-sample-app
```

### 2. Setup AWS Infrastructure
```bash
chmod +x scripts/setup-infrastructure.sh
./scripts/setup-infrastructure.sh
```

### 3. Configure Jenkins
1. Install required plugins:
   - AWS Pipeline
   - Docker Pipeline
   - GitHub Integration

2. Configure AWS credentials in Jenkins
3. Create new Pipeline job pointing to your repository
4. Set up GitHub webhook for automatic triggers

### 4. Deploy Application
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## Pipeline Flow

### 1. Code Commit & Trigger
- Developer pushes code to GitHub
- Webhook triggers Jenkins pipeline automatically

### 2. Build Stage
```bash
npm install          # Install dependencies
npm test            # Run unit tests
```

### 3. Docker Stage
```bash
docker build -t app:latest .
docker tag app:latest <ecr-repo>:latest
```

### 4. Registry Stage
```bash
aws ecr get-login-password | docker login
docker push <ecr-repo>:latest
```

### 5. Deploy Stage
```bash
aws ecs update-service --force-new-deployment
```

## Monitoring & Logging

### CloudWatch Integration
- **Application Logs**: `/ecs/devops-sample-app`
- **Metrics**: CPU, Memory, Network utilization
- **Alarms**: Configurable thresholds for alerts

### Accessing Logs
```bash
# View logs via AWS CLI
aws logs describe-log-groups --log-group-name-prefix "/ecs/devops-sample-app"

# Stream logs in real-time
aws logs tail /ecs/devops-sample-app --follow
```

### Key Metrics to Monitor
- Container CPU utilization
- Memory usage
- Request count and latency
- Error rates

## Local Development

### Run Locally
```bash
npm install
npm run dev
```

### Run with Docker
```bash
docker-compose up
```

### Run Tests
```bash
npm test
```

## Branching Strategy

### Main Branch
- Production-ready code
- Protected branch with required reviews
- Automatic deployment to production

### Dev Branch
- Development integration branch
- Automatic deployment to staging environment
- Feature branches merge here first

### Feature Branches
- Individual feature development
- Naming convention: `feature/description`
- Must pass all tests before merging

## Security Best Practices

### Container Security
- Non-root user execution
- Minimal base image (Alpine Linux)
- Regular security scanning via ECR

### AWS Security
- IAM roles with least privilege
- VPC with private subnets
- Security groups with minimal access

### Pipeline Security
- Secrets management via Jenkins credentials
- No hardcoded credentials in code
- Regular dependency updates

## Troubleshooting

### Common Issues

#### Jenkins Installation Issues
**Problem:** Jenkins service fails to start with exit code 1
```bash
# Check Jenkins logs
sudo journalctl -u jenkins -f

# Fix: Reinstall with proper Java version
sudo systemctl stop jenkins
sudo apt remove jenkins
sudo apt install openjdk-11-jdk

# Install Jenkins properly
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update && sudo apt install jenkins
```

#### Node.js Not Found in Jenkins
**Problem:** `npm: not found` error in pipeline
```bash
# Install Node.js on Jenkins server
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo systemctl restart jenkins
```

#### AWS CLI Not Available
**Problem:** `aws: not found` error in pipeline
```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install
sudo ln -s /usr/local/bin/aws /usr/bin/aws
sudo systemctl restart jenkins
```

#### AWS Credentials Error in Jenkins
**Problem:** `Cannot find a Username with password credential with the ID aws-credentials`
```bash
# Solution 1: Configure AWS CLI directly on Jenkins server
sudo su - jenkins
aws configure
# Enter AWS Access Key, Secret Key, Region, Output format

# Solution 2: Remove withAWS wrapper from Jenkinsfile
# Use direct AWS CLI commands instead of withAWS(credentials: 'aws-credentials')
```

#### Jest Tests Hanging
**Problem:** `Jest did not exit one second after the test run has completed`
```json
// Fix in package.json
"scripts": {
  "test": "jest --forceExit --detectOpenHandles"
}
```

#### Missing Test Script
**Problem:** `Missing script: "test"` error
```json
// Add to package.json
"scripts": {
  "start": "node app.js",
  "test": "jest --forceExit"
},
"devDependencies": {
  "jest": "^29.5.0",
  "supertest": "^6.3.3"
}
```

#### Docker Permission Issues
**Problem:** Jenkins can't access Docker
```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

#### GitHub Webhook Not Triggering
**Problem:** Pipeline doesn't trigger automatically on git push
```bash
# In Jenkins job configuration:
# 1. Build Triggers → Check "GitHub hook trigger for GITScm polling"
# 2. Manage Jenkins → Configure Global Security → Uncheck CSRF Protection (temporarily)

# In GitHub repository:
# Settings → Webhooks → Add webhook
# URL: http://JENKINS_IP:8080/github-webhook/
# Content type: application/json
```

#### Pipeline Fails at Docker Build
```bash
# Check Docker daemon status
docker info

# Verify Dockerfile syntax
docker build --no-cache .
```

#### ECS Service Won't Start
```bash
# Check ECS service events
aws ecs describe-services --cluster devops-cluster --services devops-service

# Check task definition
aws ecs describe-task-definition --task-definition devops-sample-app

# Check CloudWatch logs
aws logs tail /ecs/devops-sample-app --follow
```

#### ECR Push Fails
```bash
# Re-authenticate with ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ecr-repo>
```

### Rollback Procedures

#### Code Rollback
```bash
# See commit history
git log --oneline

# Rollback to previous commit
git reset --hard HEAD~1
git push --force origin main

# Or revert specific commit
git revert COMMIT_HASH
git push origin main
```

#### Deployment Rollback
```bash
# ECS Console Method:
# 1. ECS → Clusters → devops-cluster → Services → devops-service
# 2. Update Service → Task Definition → Select previous revision
# 3. Update Service

# CLI Method:
aws ecs update-service --cluster devops-cluster --service devops-service --task-definition devops-sample-app:PREVIOUS_REVISION
```

#### ECR Image Rollback
```bash
# List available images
aws ecr describe-images --repository-name devops-sample-app

# Tag previous image as latest
aws ecr batch-get-image --repository-name devops-sample-app --image-ids imageTag=BUILD_NUMBER --query 'images[].imageManifest' --output text | aws ecr put-image --repository-name devops-sample-app --image-manifest file:///dev/stdin --image-tag latest

# Force ECS deployment
aws ecs update-service --cluster devops-cluster --service devops-service --force-new-deployment
```

## Cost Optimization

### AWS Resources
- **ECS Fargate**: Pay only for running containers
- **ECR**: Minimal storage costs for images
- **CloudWatch**: Free tier covers basic monitoring

### Estimated Monthly Cost
- ECS Fargate (1 task): ~$15-20
- ECR storage: ~$1-2
- CloudWatch logs: ~$1-3
- **Total**: ~$17-25/month

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review CloudWatch logs
3. Create an issue in the repository