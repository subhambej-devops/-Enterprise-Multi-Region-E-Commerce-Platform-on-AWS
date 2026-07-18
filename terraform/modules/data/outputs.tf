output "postgres_endpoint" {
  description = "Aurora PostgreSQL writer endpoint."
  value       = aws_rds_cluster.postgres.endpoint
}

output "postgres_reader_endpoint" {
  description = "Aurora PostgreSQL reader endpoint."
  value       = aws_rds_cluster.postgres.reader_endpoint
}

output "postgres_secret_arn" {
  description = "Secrets Manager ARN for managed Aurora master credentials."
  value       = aws_rds_cluster.postgres.master_user_secret[0].secret_arn
}

output "redis_primary_endpoint" {
  description = "Redis primary endpoint."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "assets_bucket_name" {
  description = "Regional assets bucket name."
  value       = aws_s3_bucket.assets.id
}

