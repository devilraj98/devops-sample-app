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
```

#### ECR Push Fails
```bash
# Re-authenticate with ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ecr-repo>
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