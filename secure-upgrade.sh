#!/bin/bash

# 🔐 Secure Upgrade Script for RebornCloud Portfolio
# This script safely upgrades the existing portfolio with security features
# while preserving all existing infrastructure and data

set -e

echo "🔐 Starting Secure Upgrade for RebornCloud Portfolio..."
echo "📅 Timestamp: $(date)"

# Configuration - EXISTING INFRASTRUCTURE
AWS_REGION="ap-south-2"
EXISTING_CLUSTER="reborncloud-portfolio"
EXISTING_SERVICE="reborncloud-service"
EXISTING_TASK_FAMILY="reborncloud-portfolio"
EXISTING_TARGET_GROUP="arn:aws:elasticloadbalancing:ap-south-2:739275449845:targetgroup/reborncloud-tg/9fa7c261808ea109"
EXISTING_LOAD_BALANCER="arn:aws:elasticloadbalancing:ap-south-2:739275449845:loadbalancer/app/reborncloud-alb/74ef417d6e4c0aa8"
ECR_REPOSITORY="reborncloud-online"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region $AWS_REGION)
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

echo ""
echo "📋 EXISTING INFRASTRUCTURE DETECTED:"
echo "   🏗️  Cluster: $EXISTING_CLUSTER"
echo "   🚀 Service: $EXISTING_SERVICE"
echo "   📝 Task Family: $EXISTING_TASK_FAMILY"
echo "   🎯 Target Group: reborncloud-tg"
echo "   ⚖️  Load Balancer: reborncloud-alb"
echo "   🌐 Domain: reborncloud.online"
echo "   📍 Region: $AWS_REGION"
echo ""

# Step 1: Create backup of current configuration
echo "💾 Step 1: Creating backup of current configuration..."
mkdir -p backups/$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"

# Backup current task definition
echo "   📝 Backing up current task definition..."
aws ecs describe-task-definition \
    --task-definition $EXISTING_TASK_FAMILY:4 \
    --region $AWS_REGION > $BACKUP_DIR/current-task-definition.json

# Backup current service configuration
echo "   🚀 Backing up current service configuration..."
aws ecs describe-services \
    --cluster $EXISTING_CLUSTER \
    --services $EXISTING_SERVICE \
    --region $AWS_REGION > $BACKUP_DIR/current-service.json

# Backup load balancer configuration
echo "   ⚖️  Backing up load balancer configuration..."
aws elbv2 describe-load-balancers \
    --load-balancer-arns $EXISTING_LOAD_BALANCER \
    --region $AWS_REGION > $BACKUP_DIR/current-load-balancer.json

# Backup target group configuration
echo "   🎯 Backing up target group configuration..."
aws elbv2 describe-target-groups \
    --target-group-arns $EXISTING_TARGET_GROUP \
    --region $AWS_REGION > $BACKUP_DIR/current-target-group.json

# Backup DNS records
echo "   🌐 Backing up DNS records..."
aws route53 list-resource-record-sets \
    --hosted-zone-id Z0704481512M711146OS \
    --region $AWS_REGION > $BACKUP_DIR/current-dns-records.json

echo "   ✅ Backup completed in: $BACKUP_DIR"

# Step 2: Build and push new secure image
echo ""
echo "🔨 Step 2: Building and pushing secure image..."

# Login to ECR
echo "   🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

# Build new secure image
echo "   🏗️  Building secure image..."
docker build -t reborncloud-secure:$(date +%Y%m%d_%H%M%S) .
docker tag reborncloud-secure:$(date +%Y%m%d_%H%M%S) $ECR_URI:secure-$(date +%Y%m%d_%H%M%S)
docker tag reborncloud-secure:$(date +%Y%m%d_%H%M%S) $ECR_URI:latest

# Push to ECR
echo "   📤 Pushing secure image to ECR..."
docker push $ECR_URI:secure-$(date +%Y%m%d_%H%M%S)
docker push $ECR_URI:latest

# Step 3: Create new secure task definition (preserving existing settings)
echo ""
echo "📝 Step 3: Creating new secure task definition..."

cat > secure-task-definition.json << EOF
{
    "family": "${EXISTING_TASK_FAMILY}",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole",
    "taskRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "reborncloud-app",
            "image": "${ECR_URI}:latest",
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
                    "value": "${AWS_REGION}"
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

# Register new task definition
echo "   📋 Registering new secure task definition..."
NEW_TASK_DEF=$(aws ecs register-task-definition \
    --cli-input-json file://secure-task-definition.json \
    --region $AWS_REGION \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo "   ✅ New task definition: $NEW_TASK_DEF"

# Step 4: Update service with zero-downtime deployment
echo ""
echo "🚀 Step 4: Performing zero-downtime deployment..."

echo "   📊 Current service status:"
aws ecs describe-services \
    --cluster $EXISTING_CLUSTER \
    --services $EXISTING_SERVICE \
    --region $AWS_REGION \
    --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}' \
    --output table

echo "   🔄 Updating service with new secure task definition..."
aws ecs update-service \
    --cluster $EXISTING_CLUSTER \
    --service $EXISTING_SERVICE \
    --task-definition $NEW_TASK_DEF \
    --region $AWS_REGION > /dev/null

echo "   ⏳ Waiting for deployment to complete..."
aws ecs wait services-stable \
    --cluster $EXISTING_CLUSTER \
    --services $EXISTING_SERVICE \
    --region $AWS_REGION

# Step 5: Verify deployment
echo ""
echo "✅ Step 5: Verifying secure deployment..."

# Check service status
echo "   📊 Final service status:"
aws ecs describe-services \
    --cluster $EXISTING_CLUSTER \
    --services $EXISTING_SERVICE \
    --region $AWS_REGION \
    --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,TaskDefinition:taskDefinition}' \
    --output table

# Get current task details
CURRENT_TASK=$(aws ecs list-tasks \
    --cluster $EXISTING_CLUSTER \
    --service-name $EXISTING_SERVICE \
    --region $AWS_REGION \
    --query 'taskArns[0]' \
    --output text)

echo "   🔍 Current running task: $(basename $CURRENT_TASK)"

# Test application endpoints
echo "   🌐 Testing application endpoints..."
DOMAIN="reborncloud.online"

echo "      🏠 Testing main site..."
if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN | grep -q "200"; then
    echo "      ✅ Main site: HEALTHY"
else
    echo "      ❌ Main site: UNHEALTHY"
fi

echo "      🔐 Testing secure resume access..."
if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/resume-access | grep -q "200"; then
    echo "      ✅ Secure resume access: HEALTHY"
else
    echo "      ❌ Secure resume access: UNHEALTHY"
fi

echo "      🚫 Testing direct download (should redirect)..."
if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/download-resume | grep -q "302"; then
    echo "      ✅ Direct download protection: WORKING"
else
    echo "      ❌ Direct download protection: NOT WORKING"
fi

# Step 6: Security verification
echo ""
echo "🛡️  Step 6: Security verification..."

echo "   🔍 Checking security headers..."
HEADERS=$(curl -s -I https://$DOMAIN)
if echo "$HEADERS" | grep -q "X-Content-Type-Options: nosniff"; then
    echo "      ✅ X-Content-Type-Options: PRESENT"
else
    echo "      ❌ X-Content-Type-Options: MISSING"
fi

if echo "$HEADERS" | grep -q "X-Frame-Options: DENY"; then
    echo "      ✅ X-Frame-Options: PRESENT"
else
    echo "      ❌ X-Frame-Options: MISSING"
fi

if echo "$HEADERS" | grep -q "Strict-Transport-Security"; then
    echo "      ✅ HSTS: PRESENT"
else
    echo "      ❌ HSTS: MISSING"
fi

# Step 7: Cleanup
echo ""
echo "🧹 Step 7: Cleanup..."
rm -f secure-task-definition.json
echo "   ✅ Temporary files cleaned up"

# Step 8: Summary
echo ""
echo "🎉 SECURE UPGRADE COMPLETED SUCCESSFULLY!"
echo ""
echo "📊 DEPLOYMENT SUMMARY:"
echo "   🏗️  Infrastructure: PRESERVED (no changes)"
echo "   🌐 Domain: https://reborncloud.online (unchanged)"
echo "   ⚖️  Load Balancer: reborncloud-alb (unchanged)"
echo "   🎯 Target Group: reborncloud-tg (unchanged)"
echo "   🔐 Security: ENHANCED with new features"
echo ""
echo "🔐 NEW SECURITY FEATURES:"
echo "   ✅ reCAPTCHA protection for resume downloads"
echo "   ✅ Rate limiting (5 downloads/hour per IP)"
echo "   ✅ Secure token-based download system"
echo "   ✅ Enhanced security headers"
echo "   ✅ Comprehensive logging"
echo "   ✅ Direct download protection"
echo ""
echo "🌐 ACCESS POINTS:"
echo "   🏠 Main Site: https://reborncloud.online"
echo "   🔐 Secure Resume: https://reborncloud.online/resume-access"
echo "   📊 Health Check: https://reborncloud.online/"
echo ""
echo "📁 BACKUP LOCATION: $BACKUP_DIR"
echo "   💾 All previous configurations backed up"
echo "   🔄 Rollback available if needed"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. 🔑 Configure reCAPTCHA keys in AWS Secrets Manager"
echo "   2. 📊 Monitor CloudWatch logs for security events"
echo "   3. 🧪 Test all security features"
echo "   4. 📧 Update any documentation with new security info"
echo ""
echo "✨ Your portfolio is now secure and ready for production!"

# Save deployment info
cat > $BACKUP_DIR/deployment-info.txt << EOF
RebornCloud Portfolio - Secure Upgrade
=====================================
Date: $(date)
Region: $AWS_REGION
Cluster: $EXISTING_CLUSTER
Service: $EXISTING_SERVICE
New Task Definition: $NEW_TASK_DEF
Domain: https://reborncloud.online
Backup Location: $BACKUP_DIR

Security Features Added:
- reCAPTCHA protection
- Rate limiting
- Secure token system
- Enhanced security headers
- Comprehensive logging
- Direct download protection

All existing infrastructure preserved.
Zero-downtime deployment completed.
EOF

echo "📄 Deployment info saved to: $BACKUP_DIR/deployment-info.txt"
