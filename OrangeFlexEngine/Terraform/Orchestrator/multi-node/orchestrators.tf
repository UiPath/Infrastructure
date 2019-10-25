

resource "flexibleengine_compute_instance_v2" "basic" {
    name            = "${format("orchestrator-%02d", count.index+1)}"
    image_id        = "${var.win_image}"
    flavor_id       = "${var.win_flavor}"
    key_pair        = "uipath"
    security_groups = ["default"]
    count           = 2
    network {
        uuid= "${flexibleengine_vpc_subnet_v1.subnet_uipath.id}"
      }
}
