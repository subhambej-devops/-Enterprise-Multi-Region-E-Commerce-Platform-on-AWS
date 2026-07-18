data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_kms_key" "data" {
  description             = "KMS key for ${var.name} data tier"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "data" {
  name          = "alias/${var.name}-data"
  target_key_id = aws_kms_key.data.key_id
}

resource "aws_security_group" "database" {
  name        = "${var.name}-database"
  description = "Database access for ${var.name}"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "database_from_nodes" {
  for_each                 = toset(var.allowed_security_group_ids)
  type                     = "ingress"
  security_group_id        = aws_security_group.database.id
  source_security_group_id = each.value
  protocol                 = "tcp"
  from_port                = 5432
  to_port                  = 5432
  description              = "PostgreSQL from EKS nodes"
}

resource "aws_security_group_rule" "database_egress" {
  type              = "egress"
  security_group_id = aws_security_group.database.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Database egress"
}

resource "aws_rds_cluster_parameter_group" "postgres" {
  name        = "${var.name}-aurora-postgres"
  family      = "aurora-postgresql15"
  description = "Aurora PostgreSQL parameters for ${var.name}"
  tags        = var.tags

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
}

resource "aws_rds_cluster" "postgres" {
  cluster_identifier              = "${var.name}-postgres"
  engine                          = "aurora-postgresql"
  engine_version                  = "15.5"
  database_name                   = "commerce"
  master_username                 = var.db_master_username
  manage_master_user_password     = true
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.data.arn
  db_subnet_group_name            = aws_db_subnet_group.database.name
  vpc_security_group_ids          = [aws_security_group.database.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.postgres.name
  backup_retention_period         = 35
  preferred_backup_window         = "03:00-04:00"
  preferred_maintenance_window    = "sun:04:00-sun:05:00"
  deletion_protection             = true
  copy_tags_to_snapshot           = true
  skip_final_snapshot             = false
  final_snapshot_identifier       = "${var.name}-postgres-final"
  tags                            = var.tags
}

resource "aws_rds_cluster_instance" "postgres" {
  count              = var.db_instance_count
  identifier         = "${var.name}-postgres-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.postgres.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.postgres.engine
  engine_version     = aws_rds_cluster.postgres.engine_version
  tags               = var.tags
}

resource "aws_db_subnet_group" "database" {
  name       = "${var.name}-database"
  subnet_ids = var.database_subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "redis" {
  name        = "${var.name}-redis"
  description = "Redis access for ${var.name}"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "redis_from_nodes" {
  for_each                 = toset(var.allowed_security_group_ids)
  type                     = "ingress"
  security_group_id        = aws_security_group.redis.id
  source_security_group_id = each.value
  protocol                 = "tcp"
  from_port                = 6379
  to_port                  = 6379
  description              = "Redis from EKS nodes"
}

resource "aws_security_group_rule" "redis_egress" {
  type              = "egress"
  security_group_id = aws_security_group.redis.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Redis egress"
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.name}-redis"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.name}-redis"
  description                = "Redis cache for ${var.name}"
  engine                     = "redis"
  node_type                  = var.redis_node_type
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  maintenance_window         = "sun:05:00-sun:06:00"
  snapshot_retention_limit   = 7
  tags                       = var.tags
}

resource "aws_s3_bucket" "assets" {
  bucket = "${var.name}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-assets"
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.data.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
