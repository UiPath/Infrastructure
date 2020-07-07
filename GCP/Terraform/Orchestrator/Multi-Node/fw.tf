resource "google_compute_firewall" "orchestrator-allow-http" {
  name    = "orchestrator-${var.deploy_id}-allow-http"
  network = google_compute_network.orchestrator.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = [
    "http-server",
  ]
}

resource "google_compute_firewall" "orchestrator-allow-https" {
  name    = "orchestrator-${var.deploy_id}-allow-https"
  network = google_compute_network.orchestrator.self_link

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags = [
    "https-server",
  ]
}

# Remote access to SQLServer
# resource "google_compute_firewall" "orchestrator-allow-sqlserver" {
#   name    = "orchestrator-${var.deploy_id}-allow-sqlserver"
#   network = google_compute_network.orchestrator.self_link
# 
#   allow {
#     protocol = "tcp"
#     ports    = ["1433"]
#   }
# 
#   source_ranges = ["0.0.0.0/0"]
# }

resource "google_compute_firewall" "orchestrator-allow-icmp" {
  name    = "orchestrator-${var.deploy_id}-allow-icmp"
  network = google_compute_network.orchestrator.self_link

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "orchestrator-allow-internal" {
  name    = "orchestrator-${var.deploy_id}-allow-internal"
  network = google_compute_network.orchestrator.self_link

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [google_compute_subnetwork.orchestrator.ip_cidr_range]
}

resource "google_compute_firewall" "orchestrator-allow-rdp" {
  name    = "orchestrator-${var.deploy_id}-allow-rdp"
  network = google_compute_network.orchestrator.self_link

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# In case you'll need to deploy some NIX
# resource "google_compute_firewall" "orchestrator-allow-ssh" {
#   name    = "orchestrator-${var.deploy_id}-allow-ssh"
#   network = google_compute_network.orchestrator.self_link
# 
#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }
# 
#   source_ranges = ["0.0.0.0/0"]
# }
