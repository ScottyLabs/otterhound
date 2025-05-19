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

5. Log in to SSO using the profile you just created: `aws sso login --profile scottylabs`.

> [!WARNING]
> If AWS opens the browser but gets stuck loading, try copying the URL and opening it in another browser, like Safari.

## Usage

> [!NOTE]
> The following commands assume that you have the environment variable `AWS_PROFILE=scottylabs` set. You can either prepend this to every command or set it once at the start of your session: `export AWS_PROFILE=scottylabs`.

Each of the following set of instructions assume you are working from the root of this repository.

### Initial (one-time) Setup

You should not need to run this step again. To create an AWS account for each environment using Organizations, use the following steps:

```
cd bootstrap/organization
tofu init
tofu plan
tofu apply
```

### Environment Deployments

```
# Replace "dev" with the appropriate environment
cd environments/dev
tofu init
tofu plan
tofu apply
```

### Common commands

* Check current AWS identity: `aws sts get-caller-identity`
* Refresh SSO credentials when they expire: `aws sso login --profile scottylabs`
* View outputs from any module: `tofu output`
