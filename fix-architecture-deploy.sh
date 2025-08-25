#!/bin/bash

# RebornCloud Portfolio - Architecture Fix & Deployment Script
# This script fixes the Docker architecture mismatch and redeploys the application

set -e

# Configuration
REGION="ap-south-2"
CLUSTER_NAME="reborncloud-portfolio"
SERVICE_NAME="reborncloud-service"
TASK_FAMILY="reborncloud-portfolio"
ECR_REPO="reborncloud-online"
ACCOUNT_ID="739275449845"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO}"

echo "🚀 Starting RebornCloud Portfolio Architecture Fix & Deployment..."
echo "=================================================="

# Step 1: Login to ECR
echo "📦 Logging into Amazon ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI

# Step 2: Build multi-architecture Docker image
echo "🔨 Building multi-architecture Docker image..."
echo "Building for linux/amd64 platform..."

# Build specifically for AMD64 (which is what Fargate uses)
docker buildx build --platform linux/amd64 -t $ECR_URI:latest --push .

echo "✅ Docker image built and pushed successfully!"

# Step 3: Force service update to pull new image
echo "🔄 Forcing ECS service update to pull new image..."
aws ecs update-service \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --force-new-deployment

echo "✅ Service update initiated!"

# Step 4: Wait for deployment to complete
echo "⏳ Waiting for deployment to complete..."
aws ecs wait services-stable \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME

echo "✅ Deployment completed successfully!"

# Step 5: Check service status
echo "📊 Checking service status..."
aws ecs describe-services \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}' \
    --output table

# Step 6: Get load balancer URL
echo "🌐 Getting application URL..."
ALB_ARN=$(aws ecs describe-services \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --query 'services[0].loadBalancers[0].targetGroupArn' \
    --output text)

if [ "$ALB_ARN" != "None" ] && [ "$ALB_ARN" != "" ]; then
    LB_ARN=$(aws elbv2 describe-target-groups \
        --region $REGION \
        --target-group-arns $ALB_ARN \
        --query 'TargetGroups[0].LoadBalancerArns[0]' \
        --output text)
    
    if [ "$LB_ARN" != "None" ] && [ "$LB_ARN" != "" ]; then
        LB_DNS=$(aws elbv2 describe-load-balancers \
            --region $REGION \
            --load-balancer-arns $LB_ARN \
            --query 'LoadBalancers[0].DNSName' \
            --output text)
        
        echo "🎉 Application should be available at: http://$LB_DNS"
    fi
fi

echo ""
echo "🎯 Architecture Fix Summary:"
echo "================================"
echo "✅ Docker image rebuilt for linux/amd64"
echo "✅ Image pushed to ECR"
echo "✅ ECS service updated with force deployment"
echo "✅ Deployment completed successfully"
echo ""
echo "🔍 To monitor the application:"
echo "aws ecs describe-services --region $REGION --cluster $CLUSTER_NAME --services $SERVICE_NAME"
echo ""
echo "🌐 Your RebornCloud Portfolio should now be running correctly!"
