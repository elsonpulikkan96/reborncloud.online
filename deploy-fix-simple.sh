#!/bin/bash

# Simple deployment script to fix the 504 issues
set -e

echo "🚀 Starting simple deployment fix..."

AWS_REGION="ap-south-2"
CLUSTER_NAME="reborncloud-portfolio"
SERVICE_NAME="reborncloud-service"

# Force new deployment with the existing image but updated command
echo "🔄 Forcing new deployment..."
aws ecs update-service \
    --region ${AWS_REGION} \
    --cluster ${CLUSTER_NAME} \
    --service ${SERVICE_NAME} \
    --force-new-deployment

echo "⏳ Waiting for service to stabilize..."
aws ecs wait services-stable \
    --region ${AWS_REGION} \
    --cluster ${CLUSTER_NAME} \
    --services ${SERVICE_NAME}

echo "✅ Deployment complete!"
echo "🌐 Check your site: https://reborncloud.online"
