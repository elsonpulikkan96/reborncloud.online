#!/bin/bash

# Comprehensive UI Fix Deployment Script
# This script will ensure the modern UI is properly deployed

set -e

echo "🔧 Starting comprehensive UI fix deployment..."

# 1. Update GitHub repository first
echo "📤 Pushing latest changes to GitHub..."
git add .
git commit -m "Fix: Update UI with cache-busting and modern styles" || echo "No changes to commit"
git push origin main || echo "Push failed or already up to date"

# 2. Build new Docker image with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
IMAGE_TAG="ui-fix-${TIMESTAMP}"

echo "🐳 Building Docker image with tag: ${IMAGE_TAG}"
docker build --platform linux/amd64 -t reborncloud-online:${IMAGE_TAG} .

# 3. Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region ap-south-2 | docker login --username AWS --password-stdin 739275449845.dkr.ecr.ap-south-2.amazonaws.com

# 4. Tag and push to ECR
echo "📤 Pushing to ECR..."
docker tag reborncloud-online:${IMAGE_TAG} 739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:${IMAGE_TAG}
docker tag reborncloud-online:${IMAGE_TAG} 739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:latest
docker push 739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:${IMAGE_TAG}
docker push 739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:latest

# 5. Create new task definition
echo "📋 Creating new task definition..."
TASK_DEF_JSON=$(cat <<EOF
{
    "family": "reborncloud-portfolio",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": "arn:aws:iam::739275449845:role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "reborncloud-app",
            "image": "739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:${IMAGE_TAG}",
            "portMappings": [
                {
                    "containerPort": 8080,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/reborncloud-portfolio",
                    "awslogs-region": "ap-south-2",
                    "awslogs-stream-prefix": "ecs"
                }
            },
            "environment": [
                {
                    "name": "FLASK_ENV",
                    "value": "production"
                },
                {
                    "name": "PORT",
                    "value": "8080"
                }
            ]
        }
    ]
}
EOF
)

# Register new task definition
NEW_TASK_DEF=$(aws ecs register-task-definition --region ap-south-2 --cli-input-json "$TASK_DEF_JSON")
NEW_REVISION=$(echo $NEW_TASK_DEF | jq -r '.taskDefinition.revision')

echo "✅ New task definition registered: reborncloud-portfolio:${NEW_REVISION}"

# 6. Update ECS service with new task definition
echo "🚀 Updating ECS service..."
aws ecs update-service \
    --region ap-south-2 \
    --cluster reborncloud-portfolio \
    --service reborncloud-service \
    --task-definition reborncloud-portfolio:${NEW_REVISION} \
    --force-new-deployment

# 7. Wait for deployment to complete
echo "⏳ Waiting for deployment to complete..."
aws ecs wait services-stable --region ap-south-2 --cluster reborncloud-portfolio --services reborncloud-service

# 8. Verify deployment
echo "🔍 Verifying deployment..."
sleep 10
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://reborncloud.online)
if [ "$RESPONSE" = "200" ]; then
    echo "✅ Website is responding correctly (HTTP $RESPONSE)"
else
    echo "❌ Website response: HTTP $RESPONSE"
fi

# 9. Check for cache-busting parameter
echo "🔍 Checking for cache-busting parameter..."
if curl -s https://reborncloud.online | grep -q "v=20250825"; then
    echo "✅ Cache-busting parameter found in HTML"
else
    echo "❌ Cache-busting parameter NOT found in HTML"
fi

echo "🎉 Deployment complete! Please clear your browser cache and check:"
echo "   - Main site: https://reborncloud.online"
echo "   - Resume access: https://reborncloud.online/resume-access"
echo ""
echo "💡 If you still see the old UI, try:"
echo "   1. Hard refresh (Ctrl+F5 or Cmd+Shift+R)"
echo "   2. Open in incognito/private mode"
echo "   3. Clear browser cache completely"
echo "   4. Try a different browser"
