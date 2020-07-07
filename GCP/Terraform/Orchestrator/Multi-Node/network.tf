resource "google_compute_subnetwork" "orchestrator" {
  name          = "orchestrator-${var.deploy_id}"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.orchestrator.self_link
}

resource "google_compute_network" "orchestrator" {
  name                    = "orchestrator-${var.deploy_id}"
  auto_create_subnetworks = false
}

