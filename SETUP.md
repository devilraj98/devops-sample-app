# DevOps Pipeline Setup Guide

## Step-by-Step Implementation

### Phase 1: Repository Setup

1. **Fork the sample repository**
   ```bash
   git clone https://github.com/SwayattDrishtigochar/devops-task.git
   cd devops-task
   ```

2. **Create your own repository and push code**
   ```bash
   git remote set-url origin <your-github-repo-url>
   git push -u origin main
   ```

3. **Create dev branch**
   ```bash
   git checkout -b dev
   git push -u origin dev
   ```

### Phase 2: AWS Infrastructure Setup

1. **Configure AWS CLI**
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Access Key, Region (us-east-1), and output format (json)
   ```

2. **Deploy infrastructure with Terraform**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Note the outputs** (ECR repository URL, ECS cluster name, etc.)

### Phase 3: Jenkins Configuration

1. **Install Jenkins plugins**:
   - AWS Pipeline Steps
   - Docker Pipeline
   - GitHub Integration
   - Blue Ocean (optional)

2. **Configure AWS credentials in Jenkins**:
   - Go to Manage Jenkins → Manage Credentials
   - Add AWS credentials with ID: `aws-credentials`

3. **Create Jenkins Pipeline**:
   - New Item → Pipeline
   - Configure GitHub repository URL
   - Set Pipeline script from SCM
   - Point to Jenkinsfile in repository

4. **Setup GitHub Webhook**:
   - Repository Settings → Webhooks
   - Add webhook: `http://your-jenkins-url/github-webhook/`
   - Select "Just the push event"

### Phase 4: Initial Deployment

1. **Build and push initial image**
   ```bash
   # Get ECR repository URL from Terraform output
   ECR_REPO=$(cd terraform && terraform output -raw ecr_repository_url)
   
   # Build and push
   docker build -t devops-sample-app:latest .
   docker tag devops-sample-app:latest ${ECR_REPO}:latest
   
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ECR_REPO}
   docker push ${ECR_REPO}:latest
   ```

2. **Update ECS service**
   ```bash
   aws ecs update-service --cluster devops-cluster --service devops-service --force-new-deployment
   ```

### Phase 5: Testing the Pipeline

1. **Make a code change**
2. **Commit and push to main branch**
3. **Verify Jenkins pipeline triggers automatically**
4. **Check deployment in AWS ECS console**

## Verification Checklist

- [ ] Repository forked and configured
- [ ] AWS infrastructure deployed via Terraform
- [ ] Jenkins configured with proper credentials
- [ ] GitHub webhook configured
- [ ] Initial deployment successful
- [ ] Pipeline triggers on code push
- [ ] Application accessible via ECS public IP
- [ ] CloudWatch logs visible
- [ ] Monitoring metrics available

## Troubleshooting

### Common Issues

**Jenkins can't connect to AWS**
- Verify AWS credentials in Jenkins
- Check IAM permissions

**Docker build fails**
- Ensure Docker is installed on Jenkins agent
- Check Dockerfile syntax

**ECS deployment fails**
- Verify ECR repository exists
- Check ECS task definition
- Review CloudWatch logs

**GitHub webhook not triggering**
- Verify webhook URL is correct
- Check Jenkins GitHub plugin configuration
- Ensure repository permissions