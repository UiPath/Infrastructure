
### ElastiCache - REDIS ###
resource "aws_elasticache_subnet_group" "default" {

  name       = "${var.elasticache}-${var.environment}-subnet"
  subnet_ids = "${data.aws_subnet_ids.private.ids}"
}

resource "aws_elasticache_replication_group" "redis-uipath" {

  replication_group_id          = "${var.elasticache}-${var.environment}"
  replication_group_description = "Redis cluster for UiPathOrchestrator"

  node_type             = "${var.redis_instance_type}"
  number_cache_clusters = 3
  port                  = 6379
  parameter_group_name  = "default.redis5.0"

  #snapshot_retention_limit = 5
  #snapshot_window          = "00:00-05:00"

  subnet_group_name          = "${aws_elasticache_subnet_group.default.name}"
  security_group_ids         = ["${aws_security_group.uipath_stack.id}"]
  automatic_failover_enabled = true

  lifecycle {
    ignore_changes = ["number_cache_clusters"]
  }

}
