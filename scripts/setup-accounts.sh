#!/bin/bash

# Ensure we're logged into SSO with management account
aws sso login --profile scottylabs
export AWS_PROFILE=scottylabs

# Get the account IDs from the organization output
cd bootstrap/organization
ACCOUNT_IDS=$(tofu output -json account_ids)
cd ../..

# Function to setup a profile
setup_profile() {
  local env=$1
  local account_id=$2

  echo "Setting up $env profile..."

  # Configure role assumption
  aws configure set role_arn "arn:aws:iam::${account_id}:role/OrganizationAccountAccessRole" --profile "scottylabs-$env"
  aws configure set source_profile scottylabs --profile "scottylabs-$env"
}

# Setup each environment
for env in dev staging prod; do
  setup_profile "$env" "$(echo "$ACCOUNT_IDS" | jq -r ".$env")"
done

echo -e "
Profiles have been configured! To use an environment:

1. Make sure you're logged into SSO:\n   aws sso login --profile scottylabs

2. Set the environment profile:\n   export AWS_PROFILE=scottylabs-dev  # or staging, prod

3. Verify you're in the correct account:\n   aws sts get-caller-identity
"
