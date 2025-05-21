#!/bin/bash

# Common functions for service management scripts

# Print usage information
print_usage() {
  local script_name=$(basename "$0")
  echo "Usage: $script_name <service-name> <environment>"
  echo "Example: $script_name keycloak dev"
  exit 1
}

# Validate environment parameter
validate_environment() {
  local env=$1
  if [[ ! "$env" =~ ^(dev|staging|prod)$ ]]; then
    echo "Environment must be one of: dev, staging, prod"
    exit 1
  fi
}

# Validate service directory exists
validate_service() {
  local service=$1
  if [ ! -d "services/$service" ]; then
    echo "Service directory services/$service does not exist"
    exit 1
  fi
}

# Verify AWS credentials and account
verify_aws_account() {
  local env=$1

  # Verify AWS credentials are working
  CALLER_IDENTITY=$(aws sts get-caller-identity)
  if [ $? -ne 0 ]; then
    echo "Error: AWS credentials are not working. Please check your AWS profile configuration."
    exit 1
  fi

  # Extract account ID from caller identity
  ACCOUNT_ID=$(echo "$CALLER_IDENTITY" | jq -r '.Account')

  # Extract expected account ID from the tfbackend file
  TFBACKEND_PATH="config/$env.tfbackend"
  if [ ! -f "$TFBACKEND_PATH" ]; then
    echo "Error: tfbackend config file not found: $TFBACKEND_PATH"
    exit 1
  fi

  EXPECTED_ACCOUNT=$(grep 'bucket' "$TFBACKEND_PATH" | grep -oE '[0-9]{12}')

  # Verify we're in the correct account for the environment
  if [ "$ACCOUNT_ID" != "$EXPECTED_ACCOUNT" ]; then
    echo -e "Error: You are authenticated as account \033[1m$AWS_PROFILE\033[0m \
($ACCOUNT_ID), but expected account \033[1mscottylabs-$env\033[0m ($EXPECTED_ACCOUNT)"
    echo "Press Enter to switch to the correct profile, or Ctrl+C to cancel..."
    read -r

    # Set the correct profile based on environment
    export AWS_PROFILE="scottylabs-$env"

    # Verify the new profile works
    CALLER_IDENTITY=$(aws sts get-caller-identity)
    if [ $? -ne 0 ]; then
      echo "Error: Failed to switch to the correct AWS profile. \
Did you forget to set up the environment accounts?"
      exit 1
    fi
  fi

  echo -e "Using account \033[1m$AWS_PROFILE\033[0m ($ACCOUNT_ID) for this command"
}

# Change to service directory
change_to_service_dir() {
  local service=$1
  cd "services/$service"
}

# Validate script arguments
validate_args() {
  local service=$1
  local env=$2

  if [ -z "$service" ] || [ -z "$env" ]; then
    print_usage
  fi

  validate_environment "$env"
  validate_service "$service"
  verify_aws_account "$env"
}

# Get the backend config path
get_backend_config() {
  local env=$1
  echo "../../config/$env.tfbackend"
}

# Get the variables file path
get_vars_file() {
  local env=$1
  echo "../../environments/$env.tfvars"
}
