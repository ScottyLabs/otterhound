# Otterhound

This repository contains Infrastructure as Code (IaC) for ScottyLabs using Terragrunt and OpenTofu.

## Setup

1. [Install Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)

> [!NOTE]
> If you are using `bash` or `zsh`, you can install autocompletions with `terragrunt --install-autocomplete`.

2. [Install `tofuenv`](https://github.com/tofuutils/tofuenv?tab=readme-ov-file#installation)

> [!NOTE]
> We use `tofuenv` to manage OpenTofu installations. Compare to `nvm` for Node.js.

3. Install OpenTofu with `tofuenv install`.

> [!NOTE]
> This will automatically target the version specified in `.opentofu-version` in this repository.
