# Bootstrap

These steps assume you are in the `bootstrap/` directory, not the repository root.

`backend/` uses local state to create the management S3 bucket. This bucket stores the state for `organization/` and the individual S3 buckets for each environment account.

## Initial Setup

Only the **first person to set up the repository** needs to follow these steps.

1. Make sure you are on the management profile:

```bash
export AWS_PROFILE=scottylabs
```

2. Comment out the `backend "s3"` block in `backend/main.tf`. This directory provisions the management state bucket, and we need to create it before we can have it contain its own state.

3. Create the management state bucket, which will initially store its state locally:

```bash
cd backend

tofu init
tofu apply

# Save the management bucket name from the output
MANAGEMENT_BUCKET=$(tofu output -raw bootstrap_bucket_name)
```

4. Using that bucket name, create `../../config/management.tfbackend` (assuming you are still in the `backend/` directory):

```terraform
bucket       = "<management-bucket-name>"
encrypt      = true
region       = "us-east-2"
use_lockfile = true
```

5. Uncomment the section from before, and migrate to remote state stored in the management bucket:

```bash
tofu init -backend-config="../../config/management.tfbackend"

# When prompted, type "yes" to migrate state to S3

# Delete the original local state files
rm terraform.tfstate
rm terraform.tfstate.backup
```

6. Configure organization with remote state:

```bash
cd ../organization

# Initialize with management state bucket
tofu init -backend-config="../../config/management.tfbackend"

# Create the organization and environment accounts
tofu plan
tofu apply

# Save the account IDs from the output
ACCOUNT_IDS=$(tofu output -json account_ids)
```

7. Create the environment state buckets, again with remote state:

```bash
cd ../env-backends

# Initialize with management state bucket
tofu init -backend-config="../../config/management.tfbackend"

# Set the account_ids variable (see env-backends/variables.tf)
echo "$ACCOUNT_IDS" | jq '{ account_ids: . }' > ./terraform.tfvars.json

# Create state buckets in each environment account
tofu plan
tofu apply

# Note the environment bucket names from the output
tofu output state_bucket_names
```

8. Using those bucket names, create partial backend configuration files for `dev`, `staging`, and `prod` in `../../config`. These should be identical to `management.tfbackend` aside from the `bucket` key.

9. Write this guide (kidding)
