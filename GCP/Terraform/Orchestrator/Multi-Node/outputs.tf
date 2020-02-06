# SQLServer endpoint
output "sql_server_endpoint" {
  description = "Public IP fro SQLServer connection"
  value       = var.create_sql == "true" ? google_sql_database_instance.sqlserver.0.public_ip_address : "Existing SQL Server is used"
}
