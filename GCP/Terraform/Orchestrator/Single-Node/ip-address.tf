# Create a Google Compute Address
resource "google_compute_address" "address" {
  count  = "${var.instance_count}"
  name   = "orchestrator-address${count.index}"
  region = "${var.region}"
}
