# Create a Google Compute Address
resource "google_compute_global_address" "address" {
  name = "orchestrator"
}
