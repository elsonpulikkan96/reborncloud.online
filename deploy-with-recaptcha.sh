#!/bin/bash

# Deploy RebornCloud Portfolio with reCAPTCHA Configuration
# Usage: ./deploy-with-recaptcha.sh

set -e

echo "🔐 RebornCloud Portfolio - Production reCAPTCHA Deployment"
echo "=========================================================="

# Check if reCAPTCHA keys are provided
if [ -z "$RECAPTCHA_SITE_KEY" ] || [ -z "$RECAPTCHA_SECRET_KEY" ]; then
    echo ""
    echo "❌ reCAPTCHA keys not found in environment variables!"
    echo ""
    echo "Please set your reCAPTCHA keys first:"
    echo "export RECAPTCHA_SITE_KEY='your_site_key_here'"
    echo "export RECAPTCHA_SECRET_KEY='your_secret_key_here'"
    echo ""
    echo "Get your keys from: https://www.google.com/recaptcha/admin/create"
    echo "Choose: reCAPTCHA v2 -> 'I'm not a robot' Checkbox"
    echo "Domain: reborncloud.online"
    echo ""
    exit 1
fi

echo "✅ reCAPTCHA keys found in environment"
echo "📝 Site Key: ${RECAPTCHA_SITE_KEY:0:20}..."
echo "🔑 Secret Key: ${RECAPTCHA_SECRET_KEY:0:20}..."

# Get current timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
echo "📅 Deployment timestamp: $TIMESTAMP"

# Build the production image with reCAPTCHA
echo ""
echo "🏗️  Building production image with reCAPTCHA..."
docker build --platform linux/amd64 -t reborncloud-production:$TIMESTAMP .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi

echo "✅ Image built successfully"

# Login to ECR
echo ""
echo "🔐 Logging into AWS ECR..."
aws ecr get-login-password --region ap-south-2 | docker login --username AWS --password-stdin 739275449845.dkr.ecr.ap-south-2.amazonaws.com

if [ $? -ne 0 ]; then
    echo "❌ ECR login failed!"
    exit 1
fi

# Tag and push the image
echo ""
echo "📤 Pushing production image to ECR..."
docker tag reborncloud-production:$TIMESTAMP 739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:latest
docker push 739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:latest

if [ $? -ne 0 ]; then
    echo "❌ Image push failed!"
    exit 1
fi

echo "✅ Image pushed successfully"

# Create new task definition with reCAPTCHA environment variables
echo ""
echo "📋 Creating production task definition..."

cat > production-task-definition.json << EOF
{
    "family": "reborncloud-portfolio",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": "arn:aws:iam::739275449845:role/ecsTaskExecutionRole",
    "taskRoleArn": "arn:aws:iam::739275449845:role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "reborncloud-app",
            "image": "739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:latest",
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
                    "value": "ap-south-2"
                },
                {
                    "name": "PYTHONUNBUFFERED",
                    "value": "1"
                },
                {
                    "name": "RATELIMIT_STORAGE_URL",
                    "value": "memory://"
                },
                {
                    "name": "RESUME_DOWNLOAD_LIMIT",
                    "value": "5"
                },
                {
                    "name": "RECAPTCHA_SITE_KEY",
                    "value": "$RECAPTCHA_SITE_KEY"
                },
                {
                    "name": "RECAPTCHA_SECRET_KEY",
                    "value": "$RECAPTCHA_SECRET_KEY"
                }
            ],
            "healthCheck": {
                "command": [
                    "CMD-SHELL",
                    "curl -f http://localhost:8080/ || exit 1"
                ],
                "interval": 60,
                "timeout": 10,
                "retries": 2,
                "startPeriod": 30
            }
        }
    ]
}
EOF

# Register the new task definition
echo "📝 Registering production task definition..."
TASK_DEF_ARN=$(aws ecs register-task-definition --cli-input-json file://production-task-definition.json --region ap-south-2 --query 'taskDefinition.taskDefinitionArn' --output text)

if [ $? -ne 0 ]; then
    echo "❌ Task definition registration failed!"
    exit 1
fi

echo "✅ Task definition registered: $TASK_DEF_ARN"

# Update the service
echo ""
echo "🚀 Deploying to production..."
aws ecs update-service \
    --cluster reborncloud-portfolio \
    --service reborncloud-service \
    --task-definition "$TASK_DEF_ARN" \
    --region ap-south-2 > /dev/null

if [ $? -ne 0 ]; then
    echo "❌ Service update failed!"
    exit 1
fi

echo "✅ Service update initiated"

# Wait for deployment
echo ""
echo "⏳ Waiting for deployment to complete..."
echo "   This may take 2-3 minutes..."

aws ecs wait services-stable \
    --cluster reborncloud-portfolio \
    --services reborncloud-service \
    --region ap-south-2

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 PRODUCTION DEPLOYMENT SUCCESSFUL!"
    echo "========================================="
    echo ""
    echo "✅ reCAPTCHA Protection: ACTIVE"
    echo "✅ Development Mode: DISABLED"
    echo "✅ Production Security: ENABLED"
    echo ""
    echo "🌐 Test your secure portfolio:"
    echo "   Main Site: https://reborncloud.online"
    echo "   Secure Resume: https://reborncloud.online/resume-access"
    echo ""
    echo "🔐 Users will now see full reCAPTCHA verification!"
else
    echo ""
    echo "⚠️  Deployment may still be in progress..."
    echo "   Check status: aws ecs describe-services --cluster reborncloud-portfolio --services reborncloud-service --region ap-south-2"
fi

# Cleanup
rm -f production-task-definition.json

echo ""
echo "🧹 Cleanup completed"
echo "🎯 Deployment finished!"
