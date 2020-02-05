resource "google_compute_autoscaler" "orchestrator" {
  provider = google-beta

  name   = "orchestrator"
  target = google_compute_instance_group_manager.orchestrator.self_link

  autoscaling_policy {
    min_replicas    = var.instance_count
    max_replicas    = var.max_instances
    cooldown_period = 60

    load_balancing_utilization {
      target = 0.8
    }
  }
}

resource "google_compute_instance_template" "orchestrator" {
  provider = google-beta

  name           = "orchestrator"
  machine_type   = var.vm_type
  can_ip_forward = false

  disk {
    source_image = var.image
    disk_size_gb = var.disk_size
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  tags = [
    "http-server",
    "https-server",
  ]

  metadata = {
    windows-startup-script-ps1 = "${data.template_file.init.rendered}"
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
}

resource "google_compute_instance_group_manager" "orchestrator" {
  provider = google-beta

  depends_on = [google_sql_database_instance.sqlserver.0]

  name = "orchestrator"

  auto_healing_policies {
    health_check      = google_compute_health_check.orchestrator.self_link
    initial_delay_sec = 600
  }

  version {
    instance_template = google_compute_instance_template.orchestrator.self_link
    name              = "primary"
  }

  base_instance_name = "orchestrator"
}

resource "google_compute_health_check" "orchestrator" {
  provider = google-beta

  unhealthy_threshold = 3
  check_interval_sec  = 10

  name = "orchestrator-api-status"
  http_health_check {
    port_specification = "USE_SERVING_PORT"
    request_path       = "/api/status"
  }
}
