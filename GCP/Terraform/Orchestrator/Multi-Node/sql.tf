resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta

  count = var.create_sql == "true" ? 1 : 0

  name          = "private-ip-address-${var.deploy_id}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.orchestrator.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  count = var.create_sql == "true" ? 1 : 0

  network                 = google_compute_network.orchestrator.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.0.name]
}

resource "google_sql_database_instance" "sqlserver" {
  provider = google-beta
  region   = var.region

  count = var.create_sql == "true" ? 1 : 0

  depends_on = [google_service_networking_connection.private_vpc_connection]

  name             = "sqlserver-${var.deploy_id}-${random_id.db_name_suffix.hex}"
  database_version = "SQLSERVER_2017_ENTERPRISE"
  root_password    = var.sql_root_pass

  settings {
    tier = "db-custom-4-16384"

    ip_configuration {
      ipv4_enabled    = "true"
      private_network = google_compute_network.orchestrator.self_link

      authorized_networks {
        name  = "sqlstudio"
        value = "0.0.0.0/0"
      }
    }
  }
}

resource "google_sql_database" "uipath" {
  count = var.create_sql == "true" ? 1 : 0
  depends_on = [google_sql_database_instance.sqlserver]

  name     = var.orchestrator_databasename
  instance = google_sql_database_instance.sqlserver.0.name
}

resource "google_sql_user" "sqlserver" {
  count = var.create_sql == "true" ? 1 : 0
  depends_on = [google_sql_database_instance.sqlserver]

  name     = var.orchestrator_databaseusername
  password = var.orchestrator_databaseuserpassword
  instance = google_sql_database_instance.sqlserver.0.name
}
