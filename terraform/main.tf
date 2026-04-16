# tfstate bucket

resource "aws_s3_bucket" "tfstate" {
  bucket = "my-projects-tfstate"
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# OIDC provider

# Note: AWS no longer validates the thumbprint for well-known OIDC providers
# like GitHub. It uses the JWKS endpoint discovered from the issuer URL instead.
# The thumbprint field is still required by the API but its value is ignored.
# Kept here for reference in case this behaviour changes in the future.
#
# data "tls_certificate" "github" {
#   url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
# }

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # This is no longer required. See above.
  # Use a dummy fingerprint. AWS needs to to be not empty, but will ignore it and
  # get it from URL "https://token.actions.githubusercontent.com"
  #
  # thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  thumbprint_list = ["0000000000000000000000000000000000000000"]
}

# OIDC role

data "aws_iam_policy_document" "github_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # This condition is redundant. AWS checks this anyway.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}

data "aws_iam_policy_document" "github_actions_perms" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.tfstate.arn,
      "${aws_s3_bucket.tfstate.arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::shorten-url-frontend",
      "arn:aws:s3:::shorten-url-frontend/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "lambda:*",
      "apigateway:*",
      "dynamodb:*",
      "ec2:*",
      "logs:*",
      "iam:*",
      "ssm:*",
      "ecr:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "github-actions-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_perms.json
}
