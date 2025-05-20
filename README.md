# Infrastructure

This repository contains Infrastructure as Code (IaC) for ScottyLabs using OpenTofu.

## Setup

1. [Install `tofuenv`](https://github.com/tofuutils/tofuenv?tab=readme-ov-file#installation). We use `tofuenv` to manage OpenTofu installations. Compare to `nvm` for Node.js.

2. Install OpenTofu with `tofuenv install`. This will automatically target the version specified in `.opentofu-version` in this repository.

3. Install the [`aws` CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions).

4. Configure the AWS CLI for SSO using `aws configure sso`. Use the following values:

```
SSO session name: scottylabs
SSO start url: https://scottylabs.awsapps.com/start/#
SSO region: us-east-2
SSO registration scopes: [use the default option]
Default client Region: us-east-2
CLI default output format: json
Profile name: scottylabs
```

5. Set up the AWS profiles for each environment: `./scripts/setup-accounts.sh`.

> [!WARNING]
> If AWS opens the browser but gets stuck loading, try copying the URL and opening it in another browser, like Safari.

## Usage

New team members should:

1. Clone this repository
2. Complete the **Setup** section above
3. Run `tofu init` in any directory they need to work with

> [!NOTE]
> The following commands assume that you have the environment variable `AWS_PROFILE` set. It is recommended to set it once at the start of your session: `export AWS_PROFILE=scottylabs-dev` (or staging, prod).

Each of the following set of instructions assume you are working from the root of this repository.

### Working with Infrastructure

This uses the `keycloak` service and the `dev` environment as an example. Change these values to your needs.

```bash
# Ensure you're working in the right account
export AWS_PROFILE=scottylabs-dev # (or staging, prod)

# Create the directory before initializing
mkdir services/keycloak

# Initialize OpenTofu (only needed once per directory)
./scripts/init-service.sh keycloak dev

# After making changes
tofu plan
tofu apply
```

### Common commands

```bash
# Refresh SSO credentials (when expired)
aws sso login --profile scottylabs

# Check current AWS identity
# (if this fails, run the above command first)
aws sts get-caller-identity

# View outputs from any module
tofu output

# Format all OpenTofu files
tofu fmt -recursive

# Validate configuration
tofu validate
```
