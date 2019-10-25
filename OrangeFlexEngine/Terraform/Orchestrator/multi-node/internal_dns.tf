resource "flexibleengine_dns_zone_v2" "uipath_local" {
  name = "uipath.local."
  email = "mircea1.costache@orange.com"
  description = "Uipath_testing_zone"
  ttl = 3000
  zone_type = "private"
  router {
    router_region = "${flexibleengine_vpc_v1.uipath.region}"
    router_id = "${flexibleengine_vpc_v1.uipath.id}"
  }

}

resource "flexibleengine_dns_recordset_v2" "rs_uipath_local" {
  zone_id = "${flexibleengine_dns_zone_v2.uipath_local.id}"
  name = "mssql.uipath.local."
  description = "record set for MSSQL "
  ttl = 3000
  type = "A"
  records = "${flexibleengine_rds_instance_v3.uipathdb.private_ips}"
}
