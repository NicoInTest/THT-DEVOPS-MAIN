#!/bin/bash

set -e

ENVIRONMENT=$1
ENVIRONMENT=${ENVIRONMENT:-devopstht}

AWS_REGION=$(aws configure get region)

echo "Cleaning up ECR repositories..."

REPO_NAME="${ENVIRONMENT}-order-api"
IMAGES=$(aws ecr list-images --repository-name ${REPO_NAME} --query 'imageIds[*]' --output json)
if [ "$IMAGES" != "[]" ]; then
    aws ecr batch-delete-image --repository-name ${REPO_NAME} --image-ids "$IMAGES"
fi

REPO_NAME="${ENVIRONMENT}-order-processor"
IMAGES=$(aws ecr list-images --repository-name ${REPO_NAME} --query 'imageIds[*]' --output json)
if [ "$IMAGES" != "[]" ]; then
    aws ecr batch-delete-image --repository-name ${REPO_NAME} --image-ids "$IMAGES"
fi

echo "ECR cleanup completed!"