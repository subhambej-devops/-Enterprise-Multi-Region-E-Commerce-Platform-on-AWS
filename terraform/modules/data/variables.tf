variable "name" {
  description = "Name prefix for data resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "database_subnet_ids" {
  description = "Database subnet IDs."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to data stores."
  type        = list(string)
}

variable "db_master_username" {
  description = "Aurora PostgreSQL master user name."
  type        = string
  default     = "commerce_admin"
}

variable "db_instance_class" {
  description = "Aurora PostgreSQL instance class."
  type        = string
  default     = "db.r6g.large"
}

variable "db_instance_count" {
  description = "Aurora PostgreSQL instance count."
  type        = number
  default     = 2
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type."
  type        = string
  default     = "cache.r7g.large"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

