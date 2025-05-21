#!/bin/bash

# Usage: ./init-service.sh <service-name> <environment>
# Example: ./init-service.sh keycloak dev

SERVICE=$1
ENV=$2

# Verify service and environment are provided
if [ -z "$SERVICE" ] || [ -z "$ENV" ]; then
    echo "Usage: $0 <service-name> <environment>"
    echo "Example: $0 keycloak dev"
    exit 1
fi

# Validate environment
if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
    echo "Environment must be one of: dev, staging, prod"
    exit 1
fi

# Check if service directory exists
if [ ! -d "services/$SERVICE" ]; then
    echo "Service directory services/$SERVICE does not exist"
    exit 1
fi

# Verify AWS credentials are working
CALLER_IDENTITY=$(aws sts get-caller-identity)
if [ $? -ne 0 ]; then
    echo "Error: AWS credentials are not working. Please check your AWS profile configuration."
    exit 1
fi

# Extract account ID from caller identity
ACCOUNT_ID=$(echo "$CALLER_IDENTITY" | jq -r '.Account')

# Extract expected account ID from the tfbackend file
TFBACKEND_PATH="config/$ENV.tfbackend"
if [ ! -f "$TFBACKEND_PATH" ]; then
    echo "Error: tfbackend config file not found: $TFBACKEND_PATH"
    exit 1
fi

EXPECTED_ACCOUNT=$(grep 'bucket' "$TFBACKEND_PATH" | grep -oE '[0-9]{12}')

# Verify we're in the correct account for the environment
if [ "$ACCOUNT_ID" != "$EXPECTED_ACCOUNT" ]; then
    echo "Error: You are authenticated as account $ACCOUNT_ID, but expected account $EXPECTED_ACCOUNT for $ENV environment"
    echo "Please ensure you're using the correct AWS profile for the $ENV environment"
    exit 1
fi

echo "Using account $AWS_PROFILE ($ACCOUNT_ID)"

# Initialize the service
cd "services/$SERVICE"
tofu init -backend-config="../../config/$ENV.tfbackend"
