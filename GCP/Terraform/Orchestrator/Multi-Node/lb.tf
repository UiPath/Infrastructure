resource "google_compute_global_forwarding_rule" "http" {
  provider = google-beta

  name = "http-${var.deploy_id}"

  ip_address            = google_compute_global_address.address.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80-80"
  target                = google_compute_target_http_proxy.orchestrator.self_link
}

resource "google_compute_global_forwarding_rule" "https" {
  provider = google-beta

  name = "https-${var.deploy_id}"

  ip_address            = google_compute_global_address.address.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443-443"
  target                = google_compute_target_https_proxy.orchestrator.self_link
}

resource "google_compute_target_http_proxy" "orchestrator" {
  provider = google-beta

  name    = "http-${var.deploy_id}"
  url_map = google_compute_url_map.orchestrator.self_link
}

resource "google_compute_managed_ssl_certificate" "orchestrator" {
  provider = google-beta

  name = "orchestrator-${var.deploy_id}"

  managed {
    domains = ["${var.orchestrator_domain}"]
  }
}

resource "google_compute_target_https_proxy" "orchestrator" {
  provider = google-beta

  ssl_certificates = [google_compute_managed_ssl_certificate.orchestrator.self_link]
  name             = "https-${var.deploy_id}"
  url_map          = google_compute_url_map.orchestrator.self_link
}

resource "google_compute_url_map" "orchestrator" {
  provider = google-beta

  name            = "orchestrator-${var.deploy_id}"
  default_service = google_compute_backend_service.orchestrator.self_link
}

resource "google_compute_backend_service" "orchestrator" {
  provider = google-beta

  load_balancing_scheme = "EXTERNAL"

  backend {
    group          = google_compute_instance_group_manager.orchestrator.instance_group
    balancing_mode = "UTILIZATION"
  }

  name        = "orchestrator-${var.deploy_id}"
  protocol    = "HTTP"
  timeout_sec = 60

  health_checks = [google_compute_health_check.orchestrator.self_link]
}
