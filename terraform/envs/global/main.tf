data "aws_caller_identity" "current" {}

locals {
  name = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

module "ecr" {
  source = "../../modules/ecr"

  name     = var.project_name
  services = var.services
  replication_destinations = [
    for region in var.replication_regions : {
      region      = region
      registry_id = data.aws_caller_identity.current.account_id
    }
  ]
  tags = local.common_tags
}

module "security" {
  source = "../../modules/security"

  name                = var.project_name
  github_repositories = var.github_repositories
  tags                = local.common_tags
}

module "edge" {
  count  = var.enable_edge ? 1 : 0
  source = "../../modules/edge"

  name                         = var.project_name
  domain_name                  = var.domain_name
  hosted_zone_id               = var.hosted_zone_id
  certificate_arn              = var.certificate_arn
  primary_origin_domain_name   = var.primary_origin_domain_name
  secondary_origin_domain_name = var.secondary_origin_domain_name
  tags                         = local.common_tags
}

resource "aws_budgets_budget" "monthly" {
  count = length(var.budget_alert_emails) > 0 ? 1 : 0

  name         = "${var.project_name}-monthly"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_alert_emails
  }
}
