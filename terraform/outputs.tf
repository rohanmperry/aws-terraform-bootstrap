output "role_arn" {
  description = "Add this as AWS_ROLE_ARN in each project's GitHub secrets"
  value       = aws_iam_role.github_actions.arn
}

output "tfstate_bucket" {
  description = "Use this as the bucket in each project's S3 backend config"
  value       = aws_s3_bucket.tfstate.bucket
}
