variable "project_name" {
  description = "Project name."
  type        = string
  default     = "enterprise-commerce"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "global"
}

variable "region" {
  description = "AWS region for global edge resources. CloudFront WAF must use us-east-1."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.region == "us-east-1"
    error_message = "The global stack must run in us-east-1 because CloudFront WAF ACLs are global resources managed from us-east-1."
  }
}

variable "services" {
  description = "Service repositories to create in ECR."
  type        = list(string)
  default     = ["catalog", "cart", "checkout"]
}

variable "replication_regions" {
  description = "Destination regions for ECR image replication."
  type        = list(string)
  default     = ["us-west-2"]
}

variable "github_repositories" {
  description = "GitHub repositories allowed to assume the deploy role."
  type        = list(string)

  validation {
    condition     = alltrue([for repo in var.github_repositories : can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", repo))])
    error_message = "Each GitHub repository must be formatted as owner/repository."
  }
}

variable "enable_edge" {
  description = "Create CloudFront, WAF, and Route 53 records after regional origins exist."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Public DNS name for the platform."
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID."
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for the platform domain."
  type        = string
  default     = ""
}

variable "primary_origin_domain_name" {
  description = "Primary region ingress DNS name."
  type        = string
  default     = ""
}

variable "secondary_origin_domain_name" {
  description = "Secondary region ingress DNS name."
  type        = string
  default     = ""
}

variable "monthly_budget_usd" {
  description = "Optional monthly cost budget in USD."
  type        = string
  default     = "5000"

  validation {
    condition     = can(tonumber(var.monthly_budget_usd)) && tonumber(var.monthly_budget_usd) > 0
    error_message = "monthly_budget_usd must be a positive numeric string, for example 5000 or 5000.00."
  }
}

variable "budget_alert_emails" {
  description = "Email addresses that receive cost budget alerts."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}
