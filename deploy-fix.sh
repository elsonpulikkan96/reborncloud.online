#!/bin/bash

# RebornCloud Portfolio - Quick Fix Deployment
# This script fixes the 504 Gateway Timeout issues

set -e

echo "🚀 Starting RebornCloud Portfolio Fix Deployment..."

# Configuration
AWS_REGION="ap-south-2"
ECR_REPOSITORY="reborncloud-online"
CLUSTER_NAME="reborncloud-portfolio"
SERVICE_NAME="reborncloud-service"
TASK_FAMILY="reborncloud-portfolio"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

echo "📋 Configuration:"
echo "   AWS Region: ${AWS_REGION}"
echo "   ECR Repository: ${ECR_URI}"
echo "   ECS Cluster: ${CLUSTER_NAME}"
echo "   ECS Service: ${SERVICE_NAME}"

# Step 1: Build Docker image
echo "🔨 Building Docker image..."
docker build -t ${ECR_REPOSITORY}:latest .

# Step 2: Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}

# Step 3: Tag and push image
echo "📤 Pushing image to ECR..."
docker tag ${ECR_REPOSITORY}:latest ${ECR_URI}:latest
docker push ${ECR_URI}:latest

# Step 4: Get current task definition
echo "📋 Getting current task definition..."
TASK_DEFINITION=$(aws ecs describe-task-definition \
    --task-definition ${TASK_FAMILY} \
    --region ${AWS_REGION} \
    --query 'taskDefinition' \
    --output json)

# Step 5: Update task definition with new image
echo "🔄 Creating new task definition..."
NEW_TASK_DEFINITION=$(echo $TASK_DEFINITION | jq --arg IMAGE "${ECR_URI}:latest" '
    .containerDefinitions[0].image = $IMAGE |
    .containerDefinitions[0].command = [
        "gunicorn",
        "--bind", "0.0.0.0:8080",
        "--workers", "2",
        "--timeout", "60",
        "--keep-alive", "2",
        "--max-requests", "1000",
        "run:app"
    ] |
    del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)
')

# Step 6: Register new task definition
echo "📝 Registering new task definition..."
NEW_TASK_DEF_ARN=$(echo $NEW_TASK_DEFINITION | aws ecs register-task-definition \
    --region ${AWS_REGION} \
    --cli-input-json file:///dev/stdin \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo "✅ New task definition registered: ${NEW_TASK_DEF_ARN}"

# Step 7: Update ECS service
echo "🔄 Updating ECS service..."
aws ecs update-service \
    --region ${AWS_REGION} \
    --cluster ${CLUSTER_NAME} \
    --service ${SERVICE_NAME} \
    --task-definition ${NEW_TASK_DEF_ARN} \
    --force-new-deployment

echo "⏳ Waiting for service to stabilize..."
aws ecs wait services-stable \
    --region ${AWS_REGION} \
    --cluster ${CLUSTER_NAME} \
    --services ${SERVICE_NAME}

# Step 8: Verify deployment
echo "🔍 Verifying deployment..."
SERVICE_STATUS=$(aws ecs describe-services \
    --region ${AWS_REGION} \
    --cluster ${CLUSTER_NAME} \
    --services ${SERVICE_NAME} \
    --query 'services[0].deployments[0].status' \
    --output text)

RUNNING_COUNT=$(aws ecs describe-services \
    --region ${AWS_REGION} \
    --cluster ${CLUSTER_NAME} \
    --services ${SERVICE_NAME} \
    --query 'services[0].runningCount' \
    --output text)

echo "📊 Deployment Status:"
echo "   Service Status: ${SERVICE_STATUS}"
echo "   Running Tasks: ${RUNNING_COUNT}"

if [ "$SERVICE_STATUS" = "PRIMARY" ] && [ "$RUNNING_COUNT" -gt "0" ]; then
    echo "✅ Deployment successful!"
    echo "🌐 Your portfolio should be available at: https://reborncloud.online"
    echo ""
    echo "🔍 To check logs:"
    echo "   aws logs tail /ecs/reborncloud-task --region ${AWS_REGION} --follow"
    echo ""
    echo "🏥 To check health:"
    echo "   curl https://reborncloud.online/health"
else
    echo "❌ Deployment may have issues. Check ECS console for details."
    exit 1
fi

echo "🎉 RebornCloud Portfolio Fix Deployment Complete!"
