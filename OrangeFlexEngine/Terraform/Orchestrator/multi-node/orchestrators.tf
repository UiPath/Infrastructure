resource "flexibleengine_compute_instance_v2" "basic" {
    name            = "${format("orchestrator-%02d", count.index+1)}"
    image_id        = "${var.win_image}"
    flavor_id       = "${var.win_flavor}"
    key_pair        = "uipath"
    security_groups = ["${var.default_sec_group}"]
    count           = "${var.orchestrator_count}"

    network {
        uuid        = "${flexibleengine_vpc_subnet_v1.subnet_uipath.id}"
      }
    user_data       = "${data.template_file.init.rendered}"
    depends_on      = ["flexibleengine_nat_snat_rule_v2.snat_uipath"]
    }
