/**
 * RDS Terraform Configuration
  * - Creates a new RDS instance with specified configurations
  * - Configurable instance type, storage, and backup settings
  */

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  # RDS instance settings
  identifier           = var.rds_instance_name
  engine               = var.rds_engine
  engine_version       = var.rds_engine_version
  family               = var.rds_engine == "sqlserver-se" ? "sqlserver-se-15" : "sqlserver-ee-15"
  major_engine_version = var.rds_engine_version
  instance_class       = var.rds_instance_type

  storage_type          = "gp3"
  allocated_storage     = var.rds_storage_size
  max_allocated_storage = var.rds_storage_size

  # Encryption at rest is not available for DB instances running SQL Server Express Edition
  storage_encrypted = var.rds_storage_encrypted

  # Authentication
  # Disable password management with secret manager
  manage_master_user_password = false
  username                    = var.rds_username
  password                    = var.rds_password
  port                        = var.rds_port

  multi_az               = var.rds_multi_az
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.db_sg.security_group_id]

  maintenance_window = var.rds_maintenance_window
  backup_window      = var.rds_backup_window

  backup_retention_period = var.rds_backup_retention_period
  skip_final_snapshot     = true
  deletion_protection     = var.rds_deletion_protection

  options                   = []
  create_db_parameter_group = false
  license_model             = var.rds_license_model
  timezone                  = var.rds_timezone
  character_set_name        = "Latin1_General_CI_AS"

  tags = var.tags
}

# Outputs

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.db.db_instance_address
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.db.db_instance_endpoint
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = module.db.db_instance_username
  sensitive   = true
}

output "db_instance_password" {
  description = "The master password for the database"
  value       = var.rds_password
  sensitive   = true
}

output "db_instance_port" {
  description = "The port for the database"
  value       = module.db.db_instance_port
}
