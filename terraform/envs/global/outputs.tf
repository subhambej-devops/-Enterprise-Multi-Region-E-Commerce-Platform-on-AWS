output "repository_urls" {
  description = "ECR repository URLs."
  value       = module.ecr.repository_urls
}

output "github_deploy_role_arn" {
  description = "GitHub Actions deploy role ARN."
  value       = module.security.github_deploy_role_arn
}

output "application_secret_arn" {
  description = "Application secret ARN."
  value       = module.security.application_secret_arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain."
  value       = try(module.edge[0].cloudfront_domain_name, null)
}

output "waf_acl_arn" {
  description = "WAF ACL ARN."
  value       = try(module.edge[0].waf_acl_arn, null)
}
