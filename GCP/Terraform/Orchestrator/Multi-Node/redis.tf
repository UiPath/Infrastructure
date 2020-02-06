resource "google_redis_instance" "orchestrator" {
  count = var.create_redis == "true" ? 1 : 0

  name           = "orchestrator-${var.deploy_id}"
  display_name   = "orchestrator-${var.deploy_id}"
  tier           = "BASIC"
  memory_size_gb = var.redis_capacity

  authorized_network = google_compute_network.orchestrator.self_link
}
