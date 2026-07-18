output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "waf_acl_arn" {
  description = "WAF ACL ARN."
  value       = aws_wafv2_web_acl.edge.arn
}

