output "github_deploy_role_arn" {
  description = "IAM role ARN used by GitHub Actions OIDC."
  value       = aws_iam_role.github_deploy.arn
}

output "application_secret_arn" {
  description = "Application bootstrap secret ARN."
  value       = aws_secretsmanager_secret.application.arn
}

