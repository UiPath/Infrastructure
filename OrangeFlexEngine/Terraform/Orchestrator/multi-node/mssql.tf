

resource "flexibleengine_rds_instance_v3" "uipathdb" {
  availability_zone = ["eu-west-0b", "eu-west-0b"]
  db {
    ##user_name  = "${var.db_username}" -FE BUG hardcoded rdsuser
    password   = "${var.db_password}"
    type       = "SQLServer"
    version    = "${var.mssql_engine}"
    port       = "1433"
  }
  name         = "${var.db_name}"
  security_group_id = "${var.default_sec_group}"
  subnet_id    = "${flexibleengine_vpc_subnet_v1.subnet_uipath.id}"
  vpc_id       = "${flexibleengine_vpc_v1.uipath.id}"
  volume {
    type       = "${var.mssql_storage_type}"
    size       = "${var.rds_allocated_storage}"
  }
  flavor       = "${var.rds_instance_class}"
  ha_replication_mode = "sync"
  backup_strategy {
    start_time = "08:00-09:00"
    keep_days = 4
  }

}
