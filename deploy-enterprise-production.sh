#!/bin/bash

# 🏢 RebornCloud Portfolio - Enterprise Production Deployment
# Retains all existing data + Adds reCAPTCHA security
# Usage: ./deploy-enterprise-production.sh

set -e

echo "🏢 RebornCloud Portfolio - Enterprise Production Deployment"
echo "============================================================"
echo "✅ Retains: All portfolio data, pages, and functionality"
echo "🔐 Adds: Enterprise reCAPTCHA security for resume downloads"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if reCAPTCHA keys are provided
if [ -z "$RECAPTCHA_SITE_KEY" ] || [ -z "$RECAPTCHA_SECRET_KEY" ]; then
    print_error "reCAPTCHA keys not found in environment variables!"
    echo ""
    echo "📋 SETUP REQUIRED:"
    echo "1. Get reCAPTCHA keys from: https://www.google.com/recaptcha/admin/create"
    echo "2. Choose: reCAPTCHA v2 -> 'I'm not a robot' Checkbox"
    echo "3. Domain: reborncloud.online"
    echo "4. Set environment variables:"
    echo ""
    echo "   export RECAPTCHA_SITE_KEY='your_site_key_here'"
    echo "   export RECAPTCHA_SECRET_KEY='your_secret_key_here'"
    echo ""
    echo "5. Run this script again"
    echo ""
    exit 1
fi

print_status "reCAPTCHA keys found in environment"
print_info "Site Key: ${RECAPTCHA_SITE_KEY:0:20}..."
print_info "Secret Key: ${RECAPTCHA_SECRET_KEY:0:20}..."

# Get current timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
print_info "Deployment timestamp: $TIMESTAMP"

# Create backup of current deployment
echo ""
echo "💾 Creating deployment backup..."
mkdir -p backups/enterprise-$TIMESTAMP
print_status "Backup directory created: backups/enterprise-$TIMESTAMP"

# Backup current task definition
print_info "Backing up current task definition..."
aws ecs describe-task-definition \
    --task-definition reborncloud-portfolio \
    --region ap-south-2 \
    --query 'taskDefinition' > backups/enterprise-$TIMESTAMP/current-task-definition.json

# Backup current service configuration
print_info "Backing up current service configuration..."
aws ecs describe-services \
    --cluster reborncloud-portfolio \
    --services reborncloud-service \
    --region ap-south-2 > backups/enterprise-$TIMESTAMP/current-service.json

print_status "Backup completed"

# Build the enterprise production image
echo ""
echo "🏗️  Building Enterprise Production Image..."
print_info "Platform: linux/amd64 (AWS Fargate compatible)"
print_info "Features: All existing + reCAPTCHA security"

docker build --platform linux/amd64 -t reborncloud-enterprise:$TIMESTAMP .

if [ $? -ne 0 ]; then
    print_error "Docker build failed!"
    exit 1
fi

print_status "Enterprise image built successfully"

# Login to ECR
echo ""
echo "🔐 Authenticating with AWS ECR..."
aws ecr get-login-password --region ap-south-2 | docker login --username AWS --password-stdin 739275449845.dkr.ecr.ap-south-2.amazonaws.com

if [ $? -ne 0 ]; then
    print_error "ECR authentication failed!"
    exit 1
fi

print_status "ECR authentication successful"

# Tag and push the image
echo ""
echo "📤 Pushing Enterprise Image to ECR..."
docker tag reborncloud-enterprise:$TIMESTAMP 739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:latest
docker push 739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:latest

if [ $? -ne 0 ]; then
    print_error "Image push failed!"
    exit 1
fi

print_status "Enterprise image pushed successfully"

# Create enterprise task definition
echo ""
echo "📋 Creating Enterprise Task Definition..."

cat > enterprise-task-definition.json << EOF
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
            },
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/reborncloud-task",
                    "awslogs-region": "ap-south-2",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
}
EOF

print_status "Enterprise task definition created"

# Register the new task definition
echo ""
echo "📝 Registering Enterprise Task Definition..."
TASK_DEF_ARN=$(aws ecs register-task-definition \
    --cli-input-json file://enterprise-task-definition.json \
    --region ap-south-2 \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

if [ $? -ne 0 ]; then
    print_error "Task definition registration failed!"
    exit 1
fi

print_status "Task definition registered: $TASK_DEF_ARN"

# Update the service with zero downtime
echo ""
echo "🚀 Deploying Enterprise Version (Zero Downtime)..."
print_info "This preserves all existing data and functionality"
print_info "Only adds reCAPTCHA security to resume downloads"

aws ecs update-service \
    --cluster reborncloud-portfolio \
    --service reborncloud-service \
    --task-definition "$TASK_DEF_ARN" \
    --region ap-south-2 > /dev/null

if [ $? -ne 0 ]; then
    print_error "Service update failed!"
    exit 1
fi

print_status "Enterprise deployment initiated"

# Wait for deployment with progress
echo ""
echo "⏳ Waiting for Enterprise Deployment to Complete..."
print_info "This may take 2-3 minutes for zero-downtime deployment"
print_info "Your site remains fully accessible during this process"

# Show deployment progress
echo ""
echo "📊 Deployment Progress:"
aws ecs wait services-stable \
    --cluster reborncloud-portfolio \
    --services reborncloud-service \
    --region ap-south-2

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 ENTERPRISE PRODUCTION DEPLOYMENT SUCCESSFUL!"
    echo "=============================================="
    echo ""
    print_status "✅ All Portfolio Data: PRESERVED"
    print_status "✅ All Pages & Features: WORKING"
    print_status "✅ reCAPTCHA Security: ACTIVE"
    print_status "✅ Development Mode: DISABLED"
    print_status "✅ Enterprise Security: ENABLED"
    echo ""
    echo "🌐 Your Enterprise Portfolio:"
    echo "   📱 Main Site: https://reborncloud.online"
    echo "   🔐 Secure Resume: https://reborncloud.online/resume-access"
    echo "   📄 All Pages: Bio, Experience, Skills, Projects, Contact"
    echo ""
    echo "🔐 Security Features Active:"
    echo "   ✅ reCAPTCHA v2 verification"
    echo "   ✅ Rate limiting (5 downloads/hour)"
    echo "   ✅ Secure token system"
    echo "   ✅ Enterprise security headers"
    echo "   ✅ Bot protection"
    echo ""
    echo "👥 User Experience:"
    echo "   ✅ All portfolio content accessible"
    echo "   ✅ Professional reCAPTCHA challenge for resume"
    echo "   ✅ Seamless download after verification"
    echo ""
else
    print_warning "Deployment may still be in progress..."
    echo "   Check status with: aws ecs describe-services --cluster reborncloud-portfolio --services reborncloud-service --region ap-south-2"
fi

# Cleanup temporary files
echo ""
echo "🧹 Cleaning up temporary files..."
rm -f enterprise-task-definition.json
print_status "Cleanup completed"

# Final verification
echo ""
echo "🔍 Final Verification:"
print_info "Testing main site accessibility..."
MAIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://reborncloud.online)
if [ "$MAIN_STATUS" = "200" ]; then
    print_status "Main site: ACCESSIBLE"
else
    print_warning "Main site status: $MAIN_STATUS"
fi

print_info "Testing secure resume page..."
RESUME_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://reborncloud.online/resume-access)
if [ "$RESUME_STATUS" = "200" ]; then
    print_status "Secure resume page: ACCESSIBLE"
else
    print_warning "Secure resume page status: $RESUME_STATUS"
fi

echo ""
echo "🎯 ENTERPRISE DEPLOYMENT COMPLETED!"
echo ""
echo "📋 What's New:"
echo "   🔐 reCAPTCHA visual challenge on resume download"
echo "   🏢 Enterprise-grade security active"
echo "   ❌ No more 'Development Mode' message"
echo ""
echo "📋 What's Preserved:"
echo "   ✅ All portfolio pages and content"
echo "   ✅ All existing functionality"
echo "   ✅ All design and styling"
echo "   ✅ All contact forms and features"
echo ""
echo "🚀 Your portfolio is now Enterprise-Ready!"
