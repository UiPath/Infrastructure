resource "google_redis_instance" "orchestrator" {
  name           = "orchestrator-cache"
  display_name   = "orchestrator-cache"
  tier           = "BASIC"
  memory_size_gb = var.redis_capacity
}
