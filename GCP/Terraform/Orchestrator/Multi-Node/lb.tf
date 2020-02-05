resource "google_compute_global_forwarding_rule" "http" {
  provider = google-beta
  # region = "${var.region}"

  name = "orchestrator-http"

  ip_address            = google_compute_global_address.address.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80-80"
  target                = google_compute_target_http_proxy.orchestrator.self_link
  # network_tier          = "PREMIUM"
}

resource "google_compute_global_forwarding_rule" "https" {
  provider = google-beta
  # region = "${var.region}"

  name = "orchestrator-https"

  ip_address            = google_compute_global_address.address.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443-443"
  target                = google_compute_target_https_proxy.orchestrator.self_link
  # network_tier          = "PREMIUM"
}

resource "google_compute_target_http_proxy" "orchestrator" {
  provider = google-beta
  # region  = "${var.region}"

  name    = "orchestrator-http"
  url_map = google_compute_url_map.orchestrator.self_link
}

resource "google_compute_managed_ssl_certificate" "orchestrator" {
  provider = google-beta

  name = "uipath-orchestrator"

  managed {
    domains = ["${var.orchestrator_domain}"]
  }
}

resource "google_compute_target_https_proxy" "orchestrator" {
  provider = google-beta
  # region  = "${var.region}"

  # ssl_certificates = ["https://www.googleapis.com/compute/v1/projects/cloudservices-poc/global/sslCertificates/gcp-li-ga"]
  ssl_certificates = [google_compute_managed_ssl_certificate.orchestrator.self_link]
  name             = "orchestrator-https"
  url_map          = google_compute_url_map.orchestrator.self_link
}

resource "google_compute_url_map" "orchestrator" {
  provider = google-beta
  # region          = "${var.region}"

  name            = "uipath-orchestrator"
  default_service = google_compute_backend_service.orchestrator.self_link
}

resource "google_compute_backend_service" "orchestrator" {
  provider = google-beta
  # region      = "${var.region}"

  load_balancing_scheme = "EXTERNAL"

  backend {
    group          = google_compute_instance_group_manager.orchestrator.instance_group
    balancing_mode = "UTILIZATION"
  }

  name        = "uipath-orchestrator"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.orchestrator.self_link]
}
