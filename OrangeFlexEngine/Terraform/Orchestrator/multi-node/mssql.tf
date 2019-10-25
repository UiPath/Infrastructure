

resource "flexibleengine_rds_instance_v3" "uipathdb" {
  availability_zone = ["eu-west-0b", "eu-west-0b"]
  db {
    password = "Uipath2019!caVreauio"
    type = "SQLServer"
    version = "${var.mssql_engine}"
    port = "1433"
  }
  name = "uipathdb_rds_instance"
  security_group_id = "ee0cf15b-a7a1-4afa-9a7f-6f3eeb81852f"
  subnet_id = "${flexibleengine_vpc_subnet_v1.subnet_uipath.id}"
  vpc_id = "${flexibleengine_vpc_v1.uipath.id}"
  volume {
    type = "${var.mssql_storage_type}"
    size = "${var.mssql_size}"
  }
  flavor = "${var.mssql_flavour}"
  ha_replication_mode = "sync"
  backup_strategy {
    start_time = "08:00-09:00"
    keep_days = 4
  }

}
