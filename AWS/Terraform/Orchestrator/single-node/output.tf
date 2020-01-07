output "public_ip" {
  description = "Public IP address assigned to the Orchestrator instance."
  value       = "${aws_instance.uipath_app_server.*.public_ip}"
}

output "mssql_id" {
  description = "Identifier of the mssql DB instance."
  value       = "${aws_db_instance.default_mssql.id}"
}

output "mssql_address" {
  description = "Address of the mssql DB instance."
  value       = "${aws_db_instance.default_mssql.address}"
}

output "public_dns" {
  description = "Public DNS name assigned to the Orchestrator instance."
  value       = "${aws_instance.uipath_app_server.*.public_dns}"
}

