variable "name" {
  description = "Name prefix for security resources."
  type        = string
}

variable "github_repositories" {
  description = "GitHub repositories allowed to assume the deployment role, formatted as owner/repo."
  type        = list(string)
}

variable "deploy_policy_arns" {
  description = "Additional IAM policy ARNs attached to the GitHub deploy role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
