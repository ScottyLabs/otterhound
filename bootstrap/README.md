# Bootstrap

This project uses remote state with OpenTofu 1.10.0's support for S3 native locking (no DynamoDB required) and Terragrunt for managing configuration.

`backend/` uses local state to create the management S3 bucket. This bucket stores the state for `organization/` and the individual S3 buckets for each environment account.

## Initial Setup

Only the **first person to set up the repository** needs to follow these steps.

1. Create the management state bucket:

```bash
cd backend
terragrunt apply
```

2. Configure organization with remote state:

```bash
cd ../organization
terragrunt apply
```

3. Create the environment state buckets:

```bash
cd ../env-backends
terragrunt apply
```
