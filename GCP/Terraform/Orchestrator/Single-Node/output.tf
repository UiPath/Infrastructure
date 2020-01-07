# Output variable: Public IP address
output "public_ip" {
  #count        = "${var.instance_count}"
  value = "${google_compute_address.address.*.address}"
}