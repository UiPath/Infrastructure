# Create a Google Compute instance Template
resource "google_compute_instance" "uipath" {
  count        = "${var.instance_count}"
  name         = "${var.app_name}-${count.index}"
  machine_type = "${var.vm_type}"
  zone         = "${var.az}"

  boot_disk {
    initialize_params {
      image = "${var.image}"
      size  = "${var.disk_size}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
      nat_ip = "${element(google_compute_address.address.*.address, count.index)}"
    }
  }

  metadata = {
    windows-startup-script-ps1 = "${data.template_file.init.rendered}"
  }

}
