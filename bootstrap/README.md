# Bootstrap

This project uses remote state with OpenTofu 1.10.0's support for S3 native locking (no DynamoDB required). `backend/` uses local state to create the S3 bucket, and all other directories use remote state stored in that bucket.

## Initial Setup

Only the **first person to set up the repository** needs to follow these steps.

1. Create the state bucket:

```bash
cd backend
tofu init
tofu apply
# Note the bucket name from the output
```

2. Configure organization with remote state:

```bash
cd ../bootstrap/organization
tofu init -backend-config="bucket=<bucket-name>" \
         -backend-config="key=bootstrap/organization/terraform.tfstate" \
         -backend-config="region=us-east-2" \
         -backend-config="use_lockfile=true" \
         -backend-config="encrypt=true"
# When prompted, type "yes" to migrate state to S3

tofu plan
tofu apply
```
