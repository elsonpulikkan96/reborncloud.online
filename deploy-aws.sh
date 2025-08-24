#!/bin/bash

# AWS Deployment Script for RebornCloud Portfolio
# Region: ap-south-2 (Asia Pacific - Hyderabad)

set -e

echo "🚀 Starting AWS Deployment for RebornCloud Portfolio..."

# Configuration
AWS_REGION="ap-south-2"
ECR_REPOSITORY="reborncloud-online"
IMAGE_TAG="latest"
CLUSTER_NAME="reborncloud-cluster"
SERVICE_NAME="reborncloud-service"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region $AWS_REGION)
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

echo "📋 Deployment Configuration:"
echo "   AWS Region: $AWS_REGION"
echo "   AWS Account: $AWS_ACCOUNT_ID"
echo "   ECR Repository: $ECR_URI"
echo "   ECS Cluster: $CLUSTER_NAME"
echo "   ECS Service: $SERVICE_NAME"

# Step 1: Create ECR Repository if it doesn't exist
echo "🏗️  Creating ECR Repository..."
aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION 2>/dev/null || \
aws ecr create-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION

# Step 2: Get ECR Login Token
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

# Step 3: Build Docker Image
echo "🔨 Building Docker Image..."
docker build -t $ECR_REPOSITORY:$IMAGE_TAG .

# Step 4: Tag Image for ECR
echo "🏷️  Tagging Image for ECR..."
docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_URI:$IMAGE_TAG

# Step 5: Push Image to ECR
echo "📤 Pushing Image to ECR..."
docker push $ECR_URI:$IMAGE_TAG

# Step 6: Create ECS Task Definition
echo "📝 Creating ECS Task Definition..."
cat > task-definition.json << EOF
{
    "family": "reborncloud-task",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "reborncloud-container",
            "image": "${ECR_URI}:${IMAGE_TAG}",
            "portMappings": [
                {
                    "containerPort": 8080,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "environment": [
                {
                    "name": "FLASK_ENV",
                    "value": "production"
                },
                {
                    "name": "DEBUG",
                    "value": "False"
                },
                {
                    "name": "HOST",
                    "value": "0.0.0.0"
                },
                {
                    "name": "PORT",
                    "value": "8080"
                },
                {
                    "name": "AWS_DEFAULT_REGION",
                    "value": "${AWS_REGION}"
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/reborncloud-task",
                    "awslogs-region": "${AWS_REGION}",
                    "awslogs-stream-prefix": "ecs"
                }
            },
            "healthCheck": {
                "command": [
                    "CMD-SHELL",
                    "curl -f http://localhost:8080/ || exit 1"
                ],
                "interval": 30,
                "timeout": 5,
                "retries": 3,
                "startPeriod": 60
            }
        }
    ]
}
EOF

# Step 7: Register Task Definition
echo "📋 Registering ECS Task Definition..."
aws ecs register-task-definition --cli-input-json file://task-definition.json --region $AWS_REGION

# Step 8: Create CloudWatch Log Group
echo "📊 Creating CloudWatch Log Group..."
aws logs create-log-group --log-group-name "/ecs/reborncloud-task" --region $AWS_REGION 2>/dev/null || echo "Log group already exists"

# Step 9: Create ECS Cluster (if it doesn't exist)
echo "🏗️  Creating ECS Cluster..."
aws ecs describe-clusters --clusters $CLUSTER_NAME --region $AWS_REGION 2>/dev/null || \
aws ecs create-cluster --cluster-name $CLUSTER_NAME --capacity-providers FARGATE --region $AWS_REGION

# Step 10: Create or Update ECS Service
echo "🚀 Creating/Updating ECS Service..."
cat > service-definition.json << EOF
{
    "serviceName": "${SERVICE_NAME}",
    "cluster": "${CLUSTER_NAME}",
    "taskDefinition": "reborncloud-task",
    "desiredCount": 1,
    "launchType": "FARGATE",
    "networkConfiguration": {
        "awsvpcConfiguration": {
            "subnets": [],
            "securityGroups": [],
            "assignPublicIp": "ENABLED"
        }
    },
    "loadBalancers": [],
    "enableExecuteCommand": true
}
EOF

# Get default VPC and subnets
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text --region $AWS_REGION)
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC" --query "Subnets[*].SubnetId" --output text --region $AWS_REGION)
SUBNET_ARRAY=$(echo $SUBNETS | tr ' ' '\n' | head -2 | tr '\n' ',' | sed 's/,$//')

# Create security group for the service
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name reborncloud-sg \
    --description "Security group for RebornCloud application" \
    --vpc-id $DEFAULT_VPC \
    --region $AWS_REGION \
    --query 'GroupId' \
    --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=reborncloud-sg" \
    --query "SecurityGroups[0].GroupId" \
    --output text \
    --region $AWS_REGION)

# Add inbound rules to security group
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 8080 \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION 2>/dev/null || echo "Security group rule already exists"

# Update service definition with actual values
sed -i.bak "s/\"subnets\": \[\]/\"subnets\": [\"$(echo $SUBNET_ARRAY | sed 's/,/","/g')\"]/" service-definition.json
sed -i.bak "s/\"securityGroups\": \[\]/\"securityGroups\": [\"$SECURITY_GROUP_ID\"]/" service-definition.json

# Check if service exists and update or create
if aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $AWS_REGION 2>/dev/null | grep -q "ACTIVE"; then
    echo "📝 Updating existing ECS Service..."
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --task-definition reborncloud-task \
        --region $AWS_REGION
else
    echo "🆕 Creating new ECS Service..."
    aws ecs create-service --cli-input-json file://service-definition.json --region $AWS_REGION
fi

# Step 11: Wait for service to be stable
echo "⏳ Waiting for service to be stable..."
aws ecs wait services-stable --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $AWS_REGION

# Step 12: Get service information
echo "📋 Getting service information..."
TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --region $AWS_REGION --query 'taskArns[0]' --output text)
TASK_DETAILS=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN --region $AWS_REGION)
PUBLIC_IP=$(echo $TASK_DETAILS | jq -r '.tasks[0].attachments[0].details[] | select(.name=="networkInterfaceId") | .value' | xargs -I {} aws ec2 describe-network-interfaces --network-interface-ids {} --region $AWS_REGION --query 'NetworkInterfaces[0].Association.PublicIp' --output text)

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Application Details:"
echo "   Public IP: $PUBLIC_IP"
echo "   Port: 8080"
echo "   URL: http://$PUBLIC_IP:8080"
echo ""
echo "📊 Monitoring:"
echo "   CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#logsV2:log-groups/log-group/%2Fecs%2Freborncloud-task"
echo "   ECS Service: https://console.aws.amazon.com/ecs/home?region=$AWS_REGION#/clusters/$CLUSTER_NAME/services/$SERVICE_NAME"
echo ""
echo "🔧 Management Commands:"
echo "   View logs: aws logs tail /ecs/reborncloud-task --follow --region $AWS_REGION"
echo "   Scale service: aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count <count> --region $AWS_REGION"
echo "   Stop service: aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count 0 --region $AWS_REGION"
echo ""

# Cleanup temporary files
rm -f task-definition.json service-definition.json service-definition.json.bak

echo "🎉 RebornCloud Portfolio is now live on AWS!"
