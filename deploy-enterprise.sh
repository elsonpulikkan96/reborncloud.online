#!/bin/bash

set -e

REGION="ap-south-2"
CLUSTER_NAME="reborncloud-portfolio"
SERVICE_NAME="reborncloud-portfolio-service"
ECR_REPO="reborncloud-portfolio"
IMAGE_TAG="enterprise-$(date +%Y%m%d-%H%M%S)"

echo "🚀 Starting Enterprise Production Deployment..."

echo "📦 Building optimized Docker image..."
docker build --platform linux/amd64 -t $ECR_REPO:$IMAGE_TAG .

echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com

echo "🏷️ Tagging image for ECR..."
docker tag $ECR_REPO:$IMAGE_TAG $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG
docker tag $ECR_REPO:$IMAGE_TAG $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:latest

echo "⬆️ Pushing to ECR..."
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:latest

echo "🔄 Updating ECS service..."
aws ecs update-service \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --force-new-deployment

echo "⏳ Waiting for deployment to complete..."
aws ecs wait services-stable \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME

echo "✅ Enterprise deployment completed successfully!"
echo "🌐 Website: https://reborncloud.online"
echo "📊 Health Check: https://reborncloud.online/health"

echo "🔍 Verifying deployment..."
sleep 30
curl -f https://reborncloud.online/health || echo "⚠️ Health check failed"

echo "🎉 Deployment verification complete!"
