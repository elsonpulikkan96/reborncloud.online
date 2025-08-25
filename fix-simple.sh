#!/bin/bash

# RebornCloud Portfolio - Simple Architecture Fix
set -e

# Configuration
REGION="ap-south-2"
CLUSTER_NAME="reborncloud-portfolio"
SERVICE_NAME="reborncloud-service"
ECR_REPO="reborncloud-online"
ACCOUNT_ID="739275449845"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO}"

echo "🚀 Starting Simple Architecture Fix..."

# Step 1: Login to ECR
echo "📦 Logging into Amazon ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI

# Step 2: Build Docker image normally (should work for AMD64)
echo "🔨 Building Docker image..."
docker build -t $ECR_URI:latest .

# Step 3: Push image
echo "📤 Pushing image to ECR..."
docker push $ECR_URI:latest

# Step 4: Force service update
echo "🔄 Forcing ECS service update..."
aws ecs update-service \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --force-new-deployment

echo "✅ Deployment initiated! Checking status in 30 seconds..."
sleep 30

# Step 5: Check service status
echo "📊 Checking service status..."
aws ecs describe-services \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}' \
    --output table

echo "🎉 Fix completed! Monitor the service for a few minutes to ensure it stabilizes."
