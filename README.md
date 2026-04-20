> **Note:** This is one of three repositories that make up the shorten-url project. 
> Start with the [shorten-url-infra README](https://github.com/yourusername/shorten-url-infra) 
> for a full overview and setup instructions.

# aws-terraform-bootstrap

Shared AWS bootstrap infrastructure for portfolio projects. Provisions the foundational 
resources required before any project CI/CD pipeline can run.

## What it creates

- **S3 bucket** — remote Terraform state storage with versioning enabled
- **IAM OIDC provider** — trusts GitHub Actions as an identity provider
- **IAM role** — assumed by GitHub Actions workflows via OIDC, no static credentials needed

## Prerequisites

- AWS CLI configured with a named profile (`projects`)
- Terraform >= 1.14
- GNU Make

## Usage

```bash
make init
make plan GITHUB_ORG=your-github-username
make apply GITHUB_ORG=your-github-username
```

After applying, note the outputs:

- `role_arn` — add as `AWS_GITHUB_ROLE_ARN` secret in each project repo
- `tfstate_bucket` — use as the S3 backend bucket in each project

## How it works

GitHub Actions workflows authenticate to AWS using OpenID Connect (OIDC) — no long-lived 
AWS credentials are stored in GitHub. When a workflow runs, GitHub mints a short-lived JWT 
signed with its private key. AWS verifies the JWT against GitHub's public key and issues 
temporary credentials valid for 1 hour.

## Related projects

- [shorten-url-infra](https://github.com/yourusername/shorten-url-infra) — AWS infrastructure for the URL shortener
- [shorten-url-app](https://github.com/yourusername/shorten-url-app) — Application code for the URL shortener
