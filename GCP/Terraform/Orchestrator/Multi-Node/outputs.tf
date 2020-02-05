# SQLServer endpoint
output "sql_server_endpoint" {
  description = "Public IP fro SQLServer connection"
  value       = google_sql_database_instance.sqlserver.0.public_ip_address
}
