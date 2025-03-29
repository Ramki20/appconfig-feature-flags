#!/bin/bash

# This script can be used to deploy feature flags manually
# Usage: ./deploy.sh <config_file_name> <environment>

set -e

CONFIG_FILE="$1"
ENVIRONMENT="${2:-dev}"

if [ -z "$CONFIG_FILE" ]; then
    echo "Error: Config file name is required"
    echo "Usage: $0 <config_file_name> [environment]"
    exit 1
fi

# Add .json extension if not present
if [[ "$CONFIG_FILE" != *.json ]]; then
    CONFIG_FILE="${CONFIG_FILE}.json"
fi

# Check if config file exists
CONFIG_PATH="config/$CONFIG_FILE"
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Error: Config file '$CONFIG_PATH' not found"
    exit 1
fi

# Validate the config file
./scripts/validate_config.sh "$CONFIG_PATH" || exit 1

# Extract config file name without extension
CONFIG_FILE_NAME=$(basename "$CONFIG_FILE" .json)

# Read config file content
CONFIG_CONTENT=$(cat "$CONFIG_PATH")

# Extract version from config file
CONFIG_VERSION=$(jq -r '.version' "$CONFIG_PATH")

echo "Deploying '$CONFIG_FILE_NAME' version $CONFIG_VERSION to environment '$ENVIRONMENT'"

# Run Terraform
cd terraform
terraform init

terraform plan \
  -var="environment=$ENVIRONMENT" \
  -var="config_file_name=$CONFIG_FILE_NAME" \
  -var="config_content=$CONFIG_CONTENT" \
  -var="config_version=$CONFIG_VERSION" \
  -out=tfplan

terraform apply -auto-approve tfplan

# Get deployment info
APPLICATION_ID=$(terraform output -raw application_id)
ENVIRONMENT_ID=$(terraform output -raw environment_id)
DEPLOYMENT_ID=$(terraform output -raw deployment_id)

echo "Monitoring deployment status..."
for i in {1..10}; do
    STATUS=$(aws appconfig get-deployment \
        --application-id "$APPLICATION_ID" \
        --environment-id "$ENVIRONMENT_ID" \
        --deployment-number "$DEPLOYMENT_ID" \
        --query "DeploymentState" \
        --output text)
    
    echo "Deployment status: $STATUS"
    
    if [ "$STATUS" == "COMPLETE" ]; then
        echo "Deployment completed successfully!"
        break
    elif [ "$STATUS" == "FAILED" ]; then
        echo "Deployment failed!"
        exit 1
    fi
    
    if [ $i -eq 10 ]; then
        echo "Deployment timed out!"
        exit 1
    fi
    
    sleep 5
done

cd ..
echo "Deployment process completed!"