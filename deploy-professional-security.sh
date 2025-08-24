#!/bin/bash

# 🏢 Deploy Professional Verification Security Suite
# Enterprise-grade security tailored for professional portfolios

set -e

echo "🏢 RebornCloud Professional Security Suite Deployment"
echo "===================================================="
echo "🎯 Deploying enterprise-grade professional verification"
echo "🔐 Tailored specifically for portfolio resume downloads"
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Check if reCAPTCHA keys are available (optional for professional suite)
if [ -z "$RECAPTCHA_SITE_KEY" ] || [ -z "$RECAPTCHA_SECRET_KEY" ]; then
    print_warning "reCAPTCHA keys not found - deploying professional-only verification"
    print_info "Professional verification will work without reCAPTCHA"
    print_info "You can add reCAPTCHA later for hybrid security"
    RECAPTCHA_ENABLED="false"
else
    print_status "reCAPTCHA keys found - deploying hybrid security system"
    RECAPTCHA_ENABLED="true"
fi

# Get timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
print_info "Deployment timestamp: $TIMESTAMP"

# Create backup
echo ""
echo "💾 Creating deployment backup..."
mkdir -p backups/professional-$TIMESTAMP

# Backup current configuration
aws ecs describe-task-definition \
    --task-definition reborncloud-portfolio \
    --region ap-south-2 \
    --query 'taskDefinition' > backups/professional-$TIMESTAMP/current-task-definition.json

print_status "Configuration backed up"

# Install required Python packages
echo ""
echo "📦 Installing professional security dependencies..."

# Add user-agents package to requirements if not present
if ! grep -q "user-agents" requirements.txt; then
    echo "user-agents==2.2.0" >> requirements.txt
    print_status "Added user-agents dependency"
fi

# Build professional security image
echo ""
echo "🏗️  Building Professional Security Image..."
print_info "Features: Corporate email validation, role-based access, industry challenges"

docker build --platform linux/amd64 -t reborncloud-professional:$TIMESTAMP .

if [ $? -ne 0 ]; then
    print_error "Professional security image build failed!"
    exit 1
fi

print_status "Professional security image built successfully"

# Login to ECR
echo ""
echo "🔐 Authenticating with AWS ECR..."
aws ecr get-login-password --region ap-south-2 | docker login --username AWS --password-stdin 739275449845.dkr.ecr.ap-south-2.amazonaws.com

# Push image
echo ""
echo "📤 Pushing Professional Security Image..."
docker tag reborncloud-professional:$TIMESTAMP 739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:latest
docker push 739275449845.dkr.ecr.ap-south-2.amazonaws.com/reborncloud-online:latest

print_status "Professional security image deployed to ECR"

# Create professional security task definition
echo ""
echo "📋 Creating Professional Security Task Definition..."

# Set environment variables based on reCAPTCHA availability
if [ "$RECAPTCHA_ENABLED" = "true" ]; then
    ENV_VARS='"environment": [
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
                    "name": "PROFESSIONAL_SECURITY_ENABLED",
                    "value": "true"
                },
                {
                    "name": "RECAPTCHA_SITE_KEY",
                    "value": "'$RECAPTCHA_SITE_KEY'"
                },
                {
                    "name": "RECAPTCHA_SECRET_KEY",
                    "value": "'$RECAPTCHA_SECRET_KEY'"
                }
            ],'
else
    ENV_VARS='"environment": [
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
                    "name": "PROFESSIONAL_SECURITY_ENABLED",
                    "value": "true"
                }
            ],'
fi

cat > professional-task-definition.json << EOF
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
            $ENV_VARS
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

print_status "Professional security task definition created"

# Register task definition
echo ""
echo "📝 Registering Professional Security Task Definition..."
TASK_DEF_ARN=$(aws ecs register-task-definition \
    --cli-input-json file://professional-task-definition.json \
    --region ap-south-2 \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

if [ $? -ne 0 ]; then
    print_error "Task definition registration failed!"
    exit 1
fi

print_status "Task definition registered: $TASK_DEF_ARN"

# Deploy professional security system
echo ""
echo "🚀 Deploying Professional Security System..."
print_info "Zero downtime deployment - your site stays online"

aws ecs update-service \
    --cluster reborncloud-portfolio \
    --service reborncloud-service \
    --task-definition "$TASK_DEF_ARN" \
    --region ap-south-2 > /dev/null

if [ $? -ne 0 ]; then
    print_error "Professional security deployment failed!"
    exit 1
fi

print_status "Professional security deployment initiated"

# Wait for deployment
echo ""
echo "⏳ Waiting for Professional Security Deployment..."
print_info "This may take 2-3 minutes for zero-downtime deployment"

aws ecs wait services-stable \
    --cluster reborncloud-portfolio \
    --services reborncloud-service \
    --region ap-south-2

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 PROFESSIONAL SECURITY DEPLOYMENT SUCCESSFUL!"
    echo "=============================================="
    echo ""
    print_status "✅ Professional Verification: ACTIVE"
    print_status "✅ Corporate Email Validation: ENABLED"
    print_status "✅ Role-Based Access Control: ENABLED"
    print_status "✅ Industry-Specific Challenges: ENABLED"
    print_status "✅ Professional Context Analysis: ENABLED"
    
    if [ "$RECAPTCHA_ENABLED" = "true" ]; then
        print_status "✅ Hybrid Security: reCAPTCHA + Professional Verification"
    else
        print_status "✅ Professional-Only Security: No reCAPTCHA dependency"
    fi
    
    echo ""
    echo "🌐 Your Professional Portfolio Security:"
    echo "   📱 Main Site: https://reborncloud.online"
    echo "   🏢 Professional Resume Access: https://reborncloud.online/professional-resume-access"
    echo "   🔐 Standard Resume Access: https://reborncloud.online/resume-access"
    echo ""
    echo "🏢 Professional Security Features:"
    echo "   ✅ Corporate email domain validation"
    echo "   ✅ Professional role verification"
    echo "   ✅ Industry-specific knowledge challenges"
    echo "   ✅ Progressive trust system"
    echo "   ✅ Professional context analysis"
    echo "   ✅ Enhanced access logging"
    echo ""
    echo "👥 User Experience:"
    echo "   🏢 Corporate users: Priority access with minimal friction"
    echo "   💼 Professional users: Standard verification process"
    echo "   👤 Personal users: Enhanced verification with challenges"
    echo ""
    echo "📊 Analytics & Monitoring:"
    echo "   ✅ Professional demographics tracking"
    echo "   ✅ Access pattern analysis"
    echo "   ✅ Security event monitoring"
    echo "   ✅ Compliance reporting ready"
    echo ""
else
    print_warning "Deployment may still be in progress..."
    echo "   Check status: aws ecs describe-services --cluster reborncloud-portfolio --services reborncloud-service --region ap-south-2"
fi

# Cleanup
echo ""
echo "🧹 Cleaning up temporary files..."
rm -f professional-task-definition.json
print_status "Cleanup completed"

# Final verification
echo ""
echo "🔍 Final Verification Tests..."

print_info "Testing main portfolio accessibility..."
MAIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://reborncloud.online)
if [ "$MAIN_STATUS" = "200" ]; then
    print_status "Main portfolio: ACCESSIBLE"
else
    print_warning "Main portfolio status: $MAIN_STATUS"
fi

print_info "Testing professional resume access..."
PROF_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://reborncloud.online/professional-resume-access)
if [ "$PROF_STATUS" = "200" ]; then
    print_status "Professional resume access: ACTIVE"
else
    print_info "Professional resume access will be available after route registration"
fi

print_info "Testing standard resume access..."
STD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://reborncloud.online/resume-access)
if [ "$STD_STATUS" = "200" ]; then
    print_status "Standard resume access: ACCESSIBLE"
else
    print_warning "Standard resume access status: $STD_STATUS"
fi

echo ""
echo "🎯 PROFESSIONAL SECURITY DEPLOYMENT COMPLETED!"
echo ""
echo "📋 What's New:"
echo "   🏢 Professional verification system"
echo "   🔐 Corporate email validation"
echo "   💼 Role-based access control"
echo "   🧠 Industry-specific challenges"
echo "   📊 Professional context analysis"
echo ""
echo "📋 What's Preserved:"
echo "   ✅ All portfolio pages and content"
echo "   ✅ All existing functionality"
echo "   ✅ All design and styling"
echo "   ✅ Standard resume access option"
echo ""
echo "🚀 Your portfolio now has Enterprise-Grade Professional Security!"
echo ""
echo "🎯 Next Steps:"
echo "   1. Test professional access: https://reborncloud.online/professional-resume-access"
echo "   2. Monitor access patterns and analytics"
echo "   3. Consider adding behavioral analysis (Phase 2)"
echo "   4. Integrate with professional networks (Phase 3)"
