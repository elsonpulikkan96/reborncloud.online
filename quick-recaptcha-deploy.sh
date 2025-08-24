#!/bin/bash

# Quick reCAPTCHA Deployment Script
# This will add visual reCAPTCHA to your portfolio

echo "🔐 Quick reCAPTCHA Deployment for RebornCloud Portfolio"
echo "======================================================"

# Check if keys are provided
if [ -z "$RECAPTCHA_SITE_KEY" ] || [ -z "$RECAPTCHA_SECRET_KEY" ]; then
    echo ""
    echo "❌ Please set your reCAPTCHA keys first!"
    echo ""
    echo "1. Get keys from: https://www.google.com/recaptcha/admin/create"
    echo "2. Choose: reCAPTCHA v2 -> 'I'm not a robot' Checkbox"
    echo "3. Domain: reborncloud.online"
    echo "4. Then run:"
    echo ""
    echo "   export RECAPTCHA_SITE_KEY='your_site_key_here'"
    echo "   export RECAPTCHA_SECRET_KEY='your_secret_key_here'"
    echo "   ./quick-recaptcha-deploy.sh"
    echo ""
    exit 1
fi

echo "✅ reCAPTCHA keys found!"
echo "📝 Site Key: ${RECAPTCHA_SITE_KEY:0:20}..."
echo "🔑 Secret Key: ${RECAPTCHA_SECRET_KEY:0:20}..."

# Build with reCAPTCHA
echo ""
echo "🏗️  Building image with reCAPTCHA..."
docker build --platform linux/amd64 -t reborncloud-recaptcha:latest .

# Login to ECR
echo ""
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region ap-south-2 | docker login --username AWS --password-stdin 739275449845.dkr.ecr.ap-south-2.amazonaws.com

# Push image
echo ""
echo "📤 Pushing image..."
docker tag reborncloud-recaptcha:latest 739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:latest
docker push 739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:latest

# Create task definition with reCAPTCHA keys
echo ""
echo "📋 Creating task definition with reCAPTCHA..."

cat > recaptcha-task-def.json << EOF
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

# Register task definition
echo "📝 Registering task definition..."
TASK_ARN=$(aws ecs register-task-definition --cli-input-json file://recaptcha-task-def.json --region ap-south-2 --query 'taskDefinition.taskDefinitionArn' --output text)

# Update service
echo ""
echo "🚀 Deploying with reCAPTCHA..."
aws ecs update-service --cluster reborncloud-portfolio --service reborncloud-service --task-definition "$TASK_ARN" --region ap-south-2 > /dev/null

echo ""
echo "⏳ Waiting for deployment..."
aws ecs wait services-stable --cluster reborncloud-portfolio --services reborncloud-service --region ap-south-2

echo ""
echo "🎉 reCAPTCHA DEPLOYMENT COMPLETE!"
echo "================================="
echo ""
echo "✅ Visual reCAPTCHA is now active!"
echo "❌ No more 'Development Mode' message"
echo "🔐 Enterprise security enabled"
echo ""
echo "🌐 Test it now:"
echo "   https://reborncloud.online/resume-access"
echo ""
echo "You should now see the reCAPTCHA checkbox!"

# Cleanup
rm -f recaptcha-task-def.json
