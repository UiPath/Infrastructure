# ### INLINE - RDS DB MSSQL ###
resource "aws_db_subnet_group" "default" {
  count = "${var.newSQL == "yes" ? 1 : 0}"
  name        = "${var.application}-${var.environment}-rds-subnet-group"
  description = "The ${var.environment} rds-mssql private subnet group."
  subnet_ids  = "${data.aws_subnet_ids.private.ids}" #["${aws_subnet.private.*.id[count.index]}"]

  tags ={
    Name = "${var.environment}-rds-mssql-subnet-group"
  }
}

resource "aws_db_instance" "default_mssql" {
  count = "${var.newSQL == "yes" ? 1 : 0}"
  depends_on                = ["aws_db_subnet_group.default[0]"]
  identifier                = "${var.db_name}"
  allocated_storage         = "${var.rds_allocated_storage}"
  license_model             = "license-included"
  storage_type              = "gp2"
  engine                    = "sqlserver-se"
  engine_version            = "14.00.3049.1.v1"
  instance_class            = "${var.rds_instance_class}"
  multi_az                  = "${var.rds_multi_az}"
  username                  = "${var.db_username}"
  password                  = "${var.db_password}"
  vpc_security_group_ids    = ["${aws_security_group.uipath_stack.id}"]
  db_subnet_group_name      = "${aws_db_subnet_group.default[0].id}"
  backup_retention_period   = 1
  skip_final_snapshot       = "${var.skip_final_snapshot}"
  final_snapshot_identifier = "${var.db_name}-mssql-final-snapshot"
}