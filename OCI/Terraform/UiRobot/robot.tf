# Compute - UiPath Robot
resource "oci_core_instance" "uirobot_instance" {
  count               = "${var.instance_count}"
  availability_domain = "${data.oci_identity_availability_domain.ad.name}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.instance_name}${count.index}"
  shape               = "${var.instance_shape}"
  subnet_id           = "${oci_core_subnet.uirobot_subnet.id}"
  hostname_label      = "${var.instance_name}${count.index}"

  metadata = {
   #user_data = "${base64encode(element(data.template_file.uirobot_setup.*.rendered, count.index))}"
   user_data = "${data.template_cloudinit_config.cloudinit_config.rendered}"
  }

  source_details {
    boot_volume_size_in_gbs = "${var.size_in_gbs}"
    source_id               = "${var.instance_image_ocid[var.region]}"
    source_type             = "image"
  }
}