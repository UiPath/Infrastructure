# // Address of the mssql DB instance.
# output "mssql_address" {
#   value = "${aws_db_instance.default_mssql.address}"
# }

output "lb_dns_name" {
  value = "${aws_lb.UiPath_ALB.dns_name}"
}


output "domain_name" {
  value = "https://${var.subdomain}.${var.domain}"
}


# output "redishostname" {
#   # value = "${aws_elasticache_cluster.redis.cache_nodes.0.address}"
#   # value = "${aws_elasticache_replication_group.redis-uipath.configuration_endpoint_address}"
#   value = "${aws_elasticache_replication_group.redis-uipath.primary_endpoint_address}"
# }


# output "redisendpoint" {
#   value = "${join(":", list(aws_elasticache_cluster.redis.cache_nodes.0.address, aws_elasticache_cluster.redis.cache_nodes.0.port))}"
# }
