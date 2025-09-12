# Manual DevOps Pipeline Setup Guide

Let's build this step by step manually to understand each component!

## Phase 1: Local Development Setup

### Step 1: Test the Application Locally
```bash
# Install dependencies
npm install

# Run tests
npm test

# Start the application
npm start
# Visit http://localhost:3000
```

### Step 2: Test with Docker
```bash
# Build Docker image
docker build -t devops-app:local .

# Run container
docker run -p 3000:3000 devops-app:local
# Visit http://localhost:3000
```

## Phase 2: AWS Manual Setup

### Step 1: Create ECR Repository
1. Go to AWS Console → ECR
2. Click "Create repository"
3. Repository name: `devops-sample-app`
4. Keep default settings
5. Click "Create repository"
6. **Note the repository URI** (e.g., `123456789.dkr.ecr.us-east-1.amazonaws.com/devops-sample-app`)

### Step 2: Push Image to ECR
```bash
# Get your account ID
aws sts get-caller-identity --query Account --output text

# Login to ECR (replace with your region and account ID)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

# Tag your image
docker tag devops-app:local 123456789.dkr.ecr.us-east-1.amazonaws.com/devops-sample-app:latest

# Push to ECR
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/devops-sample-app:latest
```

### Step 3: Create ECS Cluster
1. Go to AWS Console → ECS
2. Click "Create Cluster"
3. Cluster name: `devops-cluster`
4. Infrastructure: AWS Fargate (serverless)
5. Click "Create"

### Step 4: Create Task Definition
1. In ECS Console → Task Definitions
2. Click "Create new task definition"
3. Task definition family: `devops-sample-app`
4. Launch type: AWS Fargate
5. Operating system: Linux/X86_64
6. CPU: 0.25 vCPU
7. Memory: 0.5 GB
8. Task execution role: Create new role or use existing `ecsTaskExecutionRole`

**Container Configuration:**
- Container name: `devops-app`
- Image URI: `123456789.dkr.ecr.us-east-1.amazonaws.com/devops-sample-app:latest`
- Port mappings: Container port `3000`, Protocol `TCP`
- Log configuration: 
  - Log driver: `awslogs`
  - Log group: `/ecs/devops-sample-app` (create if doesn't exist)
  - Region: `us-east-1`
  - Stream prefix: `ecs`

### Step 5: Create ECS Service
1. Go to your cluster → Services tab
2. Click "Create"
3. Launch type: Fargate
4. Task Definition: `devops-sample-app:1`
5. Service name: `devops-service`
6. Number of tasks: 1
7. **Networking:**
   - VPC: Default VPC
   - Subnets: Select public subnets
   - Security group: Create new
     - Type: Custom TCP
     - Port: 3000
     - Source: 0.0.0.0/0
   - Auto-assign public IP: ENABLED
8. Click "Create Service"

### Step 6: Test Your Deployment
1. Go to ECS → Clusters → devops-cluster → Services → devops-service
2. Click on Tasks tab → Click on running task
3. Find the Public IP address
4. Visit `http://PUBLIC_IP:3000`

## Phase 3: Jenkins Setup

### Step 1: Install Jenkins
**On Ubuntu/Linux:**
```bash
# Install Java
sudo apt update
sudo apt install openjdk-11-jdk

# Add Jenkins repository
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Install Jenkins
sudo apt update
sudo apt install jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Step 2: Jenkins Initial Setup
1. Visit `http://your-server:8080`
2. Enter initial admin password
3. Install suggested plugins
4. Create admin user

### Step 3: Install Required Plugins
1. Manage Jenkins → Manage Plugins
2. Install these plugins:
   - AWS Steps
   - Docker Pipeline
   - GitHub Integration
   - Pipeline

### Step 4: Configure AWS Credentials
1. Manage Jenkins → Manage Credentials
2. Add Credentials → AWS Credentials
3. ID: `aws-credentials`
4. Access Key ID: Your AWS Access Key
5. Secret Access Key: Your AWS Secret Key

### Step 5: Create Jenkins Pipeline Job
1. New Item → Pipeline
2. Job name: `devops-pipeline`
3. Pipeline → Definition: Pipeline script from SCM
4. SCM: Git
5. Repository URL: Your GitHub repository
6. Branch: `*/main`
7. Script Path: `Jenkinsfile`

## Phase 4: GitHub Setup

### Step 1: Create Repository
1. Create new GitHub repository
2. Push your code:
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/yourusername/your-repo.git
git push -u origin main
```

### Step 2: Setup Webhook
1. Repository Settings → Webhooks
2. Add webhook:
   - URL: `http://your-jenkins-server:8080/github-webhook/`
   - Content type: `application/json`
   - Events: Just the push event
3. Click "Add webhook"

## Phase 5: Test Complete Pipeline

### Step 1: Update Jenkinsfile
Replace ECR repository URL in Jenkinsfile with your actual ECR URI.

### Step 2: Test Pipeline
1. Make a small change to `app.js`
2. Commit and push:
```bash
git add .
git commit -m "Test pipeline"
git push origin main
```
3. Check Jenkins dashboard for automatic build

### Step 3: Verify Deployment
1. Check Jenkins build logs
2. Verify new image in ECR
3. Check ECS service for new task
4. Test application at public IP

## Troubleshooting Guide

### Common Issues:

**ECR Login Fails:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Re-login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ECR_URI
```

**ECS Task Won't Start:**
1. Check CloudWatch logs: `/ecs/devops-sample-app`
2. Verify security group allows port 3000
3. Check task definition configuration

**Jenkins Can't Connect to AWS:**
1. Verify AWS credentials in Jenkins
2. Check IAM permissions for ECR and ECS

**GitHub Webhook Not Working:**
1. Check webhook URL is correct
2. Verify Jenkins is accessible from internet
3. Check webhook delivery in GitHub settings

## Next Steps After Manual Setup

Once you complete this manual setup:
1. ✅ Understand each AWS service
2. ✅ Know how Jenkins pipeline works  
3. ✅ Ready for Terraform automation
4. ✅ Ready for advanced monitoring
5. ✅ Ready for GitHub Actions