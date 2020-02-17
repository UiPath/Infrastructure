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
