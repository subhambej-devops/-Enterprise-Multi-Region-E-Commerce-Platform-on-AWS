output "cluster_name" {
  description = "Primary EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Primary EKS API endpoint."
  value       = module.eks.cluster_endpoint
}

output "postgres_endpoint" {
  description = "Primary Aurora writer endpoint."
  value       = module.data.postgres_endpoint
}

output "redis_primary_endpoint" {
  description = "Primary Redis endpoint."
  value       = module.data.redis_primary_endpoint
}

output "assets_bucket_name" {
  description = "Primary assets bucket."
  value       = module.data.assets_bucket_name
}

