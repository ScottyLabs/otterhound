# Infrastructure

This repository contains Infrastructure as Code (IaC) for ScottyLabs using Terragrunt and OpenTofu.

## Setup

1. [Install Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/).

2. [Install `tofuenv`](https://github.com/tofuutils/tofuenv?tab=readme-ov-file#installation). We use `tofuenv` to manage OpenTofu installations. Compare to `nvm` for Node.js.

3. Install OpenTofu with `tofuenv install`. This will automatically target the version specified in `.opentofu-version` in this repository.

4. Install the [`aws` CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions).

5. Configure the AWS CLI for SSO using `aws configure sso`. Use the following values:

```
SSO session name: scottylabs
SSO start url: https://scottylabs.awsapps.com/start/#
SSO region: us-east-2
SSO registration scopes: [use the default option]
Default client Region: us-east-2
CLI default output format: json
Profile name: scottylabs
```

6. Log in to SSO using the profile you just created: `aws sso login --profile scottylabs`.

> [!WARNING]
> If AWS opens the browser but gets stuck loading, try copying the URL and opening it in another browser, like Safari.

## Usage

New team members should:

1. Complete the **Setup** section above
2. Clone this repository

> [!NOTE]
> The following commands assume that you have the environment variable `AWS_PROFILE=scottylabs` set. You can either prepend this to every command or set it once at the start of your session: `export AWS_PROFILE=scottylabs`.

Each of the following set of instructions assume you are working from the root of this repository.

### Working with Infrastructure

```bash
# For organization changes
cd bootstrap/organization
terragrunt plan
terragrunt apply

# For environment-specific changes, e.g. "dev"
cd environments/dev
terragrunt plan
terragrunt apply
```

### Common commands

```bash
# Check current AWS identity
aws sts get-caller-identity

# Refresh SSO credentials (when expired)
aws sso login --profile scottylabs

# View outputs from any module
terragrunt output

# Format all OpenTofu files
terragrunt hcl format
tofu fmt -recursive

# Validate configuration
terragrunt validate
```
