# Bootstrap

This project uses remote state with OpenTofu 1.10.0's support for S3 native locking (no DynamoDB required).

`backend/` uses local state to create the management S3 bucket. This bucket stores the state for `organization/` and the individual S3 buckets for each environment account.

## Initial Setup

Only the **first person to set up the repository** needs to follow these steps.

1. Create the management state bucket:

```bash
cd backend
tofu init
tofu apply
# Note the bucket name from the output
```

2. Configure organization with remote state:

```bash
cd ../organization

# Initialize with management state bucket
MANAGEMENT_BUCKET=$(cd ../backend && tofu output -raw bootstrap_bucket_name)
tofu init \
  -backend-config="bucket=${MANAGEMENT_BUCKET}" \
  -backend-config="key=bootstrap/organization/terraform.tfstate" \
  -backend-config="region=us-east-2" \
  -backend-config="use_lockfile=true" \
  -backend-config="encrypt=true"

# When prompted, type "yes" to migrate state to S3

# Create the organization and environment accounts
tofu plan
tofu apply

# Note the account IDs from the output
tofu output account_ids
```

3. Create the environment state buckets:

```bash
cd ../env-backends

# Initialize with management state bucket
tofu init \
  -backend-config="bucket=${MANAGEMENT_BUCKET}" \
  -backend-config="key=bootstrap/env-backends/terraform.tfstate" \
  -backend-config="region=us-east-2" \
  -backend-config="use_lockfile=true" \
  -backend-config="encrypt=true"

# Set the management bucket variable
echo "management_state_bucket = \"${MANAGEMENT_BUCKET}\"" > terraform.tfvars

# Create state buckets in each environment account
tofu plan
tofu apply

# Note the environment bucket names from the output
tofu output state_bucket_names
```
