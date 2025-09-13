# Monitoring & Logging Guide

Complete monitoring and logging setup for the DevOps CI/CD pipeline using AWS CloudWatch.

## CloudWatch Configuration

### 1. Application Logs

**ECS Task Logs:**
- **Log Group:** `/ecs/devops-sample-app`
- **Log Stream:** Automatically created per task
- **Retention:** 30 days

**View Application Logs:**
```bash
# List log groups
aws logs describe-log-groups --log-group-name-prefix "/ecs/devops-sample-app"

# Stream logs in real-time
aws logs tail /ecs/devops-sample-app --follow

# Get logs from specific time
aws logs filter-log-events --log-group-name /ecs/devops-sample-app --start-time 1640995200000

# Search for errors
aws logs filter-log-events --log-group-name /ecs/devops-sample-app --filter-pattern "ERROR"
```

### 2. Container Metrics

**ECS Service Metrics:**
- **CPU Utilization:** `AWS/ECS/CPUUtilization`
- **Memory Utilization:** `AWS/ECS/MemoryUtilization`
- **Running Task Count:** `AWS/ECS/RunningTaskCount`

**View Metrics:**
```bash
# Get CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=devops-service Name=ClusterName,Value=devops-cluster \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-01-01T23:59:59Z \
  --period 300 \
  --statistics Average

# Get memory utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ServiceName,Value=devops-service Name=ClusterName,Value=devops-cluster \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-01-01T23:59:59Z \
  --period 300 \
  --statistics Average
```

### 3. Custom Application Metrics

**Add to app.js for custom metrics:**
```javascript
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch({region: 'us-east-1'});

// Custom metric function
function putMetric(metricName, value, unit = 'Count') {
  const params = {
    Namespace: 'DevOps/Application',
    MetricData: [{
      MetricName: metricName,
      Value: value,
      Unit: unit,
      Timestamp: new Date()
    }]
  };
  
  cloudwatch.putMetricData(params, (err, data) => {
    if (err) console.log('CloudWatch Error:', err);
  });
}

// Track requests
app.use((req, res, next) => {
  putMetric('RequestCount', 1);
  next();
});

// Track errors
app.use((err, req, res, next) => {
  putMetric('ErrorCount', 1);
  next(err);
});
```

## CloudWatch Dashboard

### 1. Create Dashboard via Console
1. **CloudWatch Console → Dashboards**
2. **Create dashboard:** `DevOps-Pipeline-Dashboard`
3. **Add widgets:**
   - ECS CPU Utilization
   - ECS Memory Utilization
   - Application Logs
   - Custom Metrics

### 2. Create Dashboard via CLI
```bash
# Create dashboard JSON
cat > dashboard.json << 'EOF'
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ServiceName", "devops-service", "ClusterName", "devops-cluster"],
          [".", "MemoryUtilization", ".", ".", ".", "."]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "ECS Service Metrics"
      }
    },
    {
      "type": "log",
      "properties": {
        "query": "SOURCE '/ecs/devops-sample-app'\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 100",
        "region": "us-east-1",
        "title": "Application Logs"
      }
    }
  ]
}
EOF

# Create dashboard
aws cloudwatch put-dashboard --dashboard-name "DevOps-Pipeline" --dashboard-body file://dashboard.json
```

## CloudWatch Alarms

### 1. High CPU Alarm
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "DevOps-High-CPU" \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=ServiceName,Value=devops-service Name=ClusterName,Value=devops-cluster
```

### 2. High Memory Alarm
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "DevOps-High-Memory" \
  --alarm-description "Alert when Memory exceeds 80%" \
  --metric-name MemoryUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=ServiceName,Value=devops-service Name=ClusterName,Value=devops-cluster
```

### 3. Application Error Alarm
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "DevOps-Application-Errors" \
  --alarm-description "Alert on application errors" \
  --metric-name ErrorCount \
  --namespace DevOps/Application \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

## Log Analysis

### 1. CloudWatch Insights Queries

**Error Analysis:**
```sql
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
```

**Request Pattern Analysis:**
```sql
fields @timestamp, @message
| filter @message like /GET/
| stats count() by bin(5m)
| sort @timestamp desc
```

**Performance Analysis:**
```sql
fields @timestamp, @message
| filter @message like /response time/
| parse @message "response time: * ms" as responseTime
| stats avg(responseTime), max(responseTime), min(responseTime) by bin(5m)
```

### 2. Log Aggregation
```bash
# Export logs to S3 for long-term storage
aws logs create-export-task \
  --log-group-name /ecs/devops-sample-app \
  --from 1640995200000 \
  --to 1641081600000 \
  --destination devops-logs-bucket \
  --destination-prefix logs/
```

## Jenkins Pipeline Monitoring

### 1. Jenkins Build Metrics
```bash
# Add to Jenkinsfile for build metrics
post {
  always {
    script {
      // Send build metrics to CloudWatch
      sh """
        aws cloudwatch put-metric-data \
          --namespace DevOps/Jenkins \
          --metric-data MetricName=BuildDuration,Value=${currentBuild.duration},Unit=Milliseconds \
          --region us-east-1
      """
    }
  }
  success {
    sh """
      aws cloudwatch put-metric-data \
        --namespace DevOps/Jenkins \
        --metric-data MetricName=SuccessfulBuilds,Value=1,Unit=Count \
        --region us-east-1
    """
  }
  failure {
    sh """
      aws cloudwatch put-metric-data \
        --namespace DevOps/Jenkins \
        --metric-data MetricName=FailedBuilds,Value=1,Unit=Count \
        --region us-east-1
    """
  }
}
```

## Accessing Monitoring Data

### 1. AWS Console
- **CloudWatch Console:** https://console.aws.amazon.com/cloudwatch/
- **ECS Console:** https://console.aws.amazon.com/ecs/
- **Logs:** CloudWatch → Logs → Log groups → `/ecs/devops-sample-app`
- **Metrics:** CloudWatch → Metrics → AWS/ECS
- **Dashboards:** CloudWatch → Dashboards → DevOps-Pipeline

### 2. CLI Commands
```bash
# Quick health check
aws ecs describe-services --cluster devops-cluster --services devops-service

# Recent logs
aws logs tail /ecs/devops-sample-app --since 1h

# Current metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=devops-service \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### 3. Mobile Access
- **AWS Mobile App:** Monitor alarms and metrics on mobile
- **CloudWatch Mobile:** Real-time monitoring on the go

## Cost Monitoring

### 1. CloudWatch Costs
```bash
# Monitor CloudWatch costs
aws ce get-cost-and-usage \
  --time-period Start=2023-01-01,End=2023-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

### 2. Log Retention Optimization
```bash
# Set log retention to reduce costs
aws logs put-retention-policy \
  --log-group-name /ecs/devops-sample-app \
  --retention-in-days 7
```

## Troubleshooting Monitoring

### Common Issues

**Logs Not Appearing:**
```bash
# Check ECS task definition log configuration
aws ecs describe-task-definition --task-definition devops-sample-app

# Check IAM permissions for ECS task execution role
aws iam get-role-policy --role-name ecsTaskExecutionRole --policy-name CloudWatchLogsPolicy
```

**Metrics Missing:**
```bash
# Check ECS service status
aws ecs describe-services --cluster devops-cluster --services devops-service

# Verify CloudWatch agent configuration
aws logs describe-log-groups --log-group-name-prefix "/aws/ecs"
```

**High CloudWatch Costs:**
```bash
# Check log group sizes
aws logs describe-log-groups --query 'logGroups[*].[logGroupName,storedBytes]' --output table

# Optimize retention policies
aws logs put-retention-policy --log-group-name /ecs/devops-sample-app --retention-in-days 3
```