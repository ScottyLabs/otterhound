#!/bin/bash

# Ensure we're logged into SSO with management account
aws sso login --profile scottylabs
export AWS_PROFILE=scottylabs

# Function to extract the account ID from the tfbackend file
get_account_id() {
  local env=$1
  grep 'bucket' "config/$env.tfbackend" | grep -oE '[0-9]{12}'
}

# Function to setup a profile
setup_profile() {
  local env=$1
  local account_id=$2

  echo "Setting up $env profile..."

  # Configure role assumption
  aws configure set role_arn "arn:aws:iam::${account_id}:role/OrganizationAccountAccessRole" --profile "scottylabs-$env"
  aws configure set source_profile scottylabs --profile "scottylabs-$env"
}

# Setup each environment using account ID from tfbackend file
for env in dev staging prod; do
  account_id=$(get_account_id "$env")
  if [ -z "$account_id" ]; then
    echo "Error: Could not extract account ID for environment: $env"
    exit 1
  fi

  setup_profile "$env" "$account_id"
done

echo -e "
Profiles have been configured! To use an environment:

1. Make sure you're logged into SSO:\n   aws sso login --profile scottylabs

2. Set the environment profile:\n   export AWS_PROFILE=scottylabs-dev  # or staging, prod

3. Verify you're in the correct account:\n   aws sts get-caller-identity
"
