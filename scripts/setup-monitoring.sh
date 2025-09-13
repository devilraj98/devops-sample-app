#!/bin/bash

set -e

echo "Setting up CloudWatch monitoring for DevOps pipeline..."

# Variables
CLUSTER_NAME="devops-cluster"
SERVICE_NAME="devops-service"
LOG_GROUP="/ecs/devops-sample-app"
REGION="us-east-1"

echo "Creating CloudWatch alarms..."

# High CPU Alarm
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
  --dimensions Name=ServiceName,Value=$SERVICE_NAME Name=ClusterName,Value=$CLUSTER_NAME \
  --region $REGION

echo "✅ High CPU alarm created"

# High Memory Alarm
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
  --dimensions Name=ServiceName,Value=$SERVICE_NAME Name=ClusterName,Value=$CLUSTER_NAME \
  --region $REGION

echo "✅ High Memory alarm created"

# Service Task Count Alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "DevOps-No-Running-Tasks" \
  --alarm-description "Alert when no tasks are running" \
  --metric-name RunningTaskCount \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 1 \
  --comparison-operator LessThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=ServiceName,Value=$SERVICE_NAME Name=ClusterName,Value=$CLUSTER_NAME \
  --region $REGION

echo "✅ Task count alarm created"

# Create Dashboard
cat > /tmp/dashboard.json << EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ServiceName", "$SERVICE_NAME", "ClusterName", "$CLUSTER_NAME"],
          [".", "MemoryUtilization", ".", ".", ".", "."],
          [".", "RunningTaskCount", ".", ".", ".", "."]
        ],
        "period": 300,
        "stat": "Average",
        "region": "$REGION",
        "title": "ECS Service Metrics"
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 6,
      "width": 24,
      "height": 6,
      "properties": {
        "query": "SOURCE '$LOG_GROUP'\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 100",
        "region": "$REGION",
        "title": "Application Logs"
      }
    }
  ]
}
EOF

aws cloudwatch put-dashboard \
  --dashboard-name "DevOps-Pipeline-Dashboard" \
  --dashboard-body file:///tmp/dashboard.json \
  --region $REGION

echo "✅ CloudWatch dashboard created"

# Set log retention
aws logs put-retention-policy \
  --log-group-name $LOG_GROUP \
  --retention-in-days 30 \
  --region $REGION

echo "✅ Log retention set to 30 days"

echo ""
echo "🎉 Monitoring setup complete!"
echo ""
echo "Access your monitoring:"
echo "📊 Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=$REGION#dashboards:name=DevOps-Pipeline-Dashboard"
echo "📋 Logs: https://console.aws.amazon.com/cloudwatch/home?region=$REGION#logsV2:log-groups/log-group/\$252Fecs\$252Fdevops-sample-app"
echo "🚨 Alarms: https://console.aws.amazon.com/cloudwatch/home?region=$REGION#alarmsV2:"
echo ""
echo "CLI Commands:"
echo "# View recent logs:"
echo "aws logs tail $LOG_GROUP --follow"
echo ""
echo "# Check service metrics:"
echo "aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME"

rm /tmp/dashboard.json