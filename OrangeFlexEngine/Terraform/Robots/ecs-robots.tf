### INLINE - W2016 STD UiPath Robot ###
### Current iteration limitation: we need to create the network in the Orchestrator terraform part

# ## collect the ID of the VOC
# data "flexibleengine_vpc_v1" "vpc" {
#   name = "${var.vpc_name}"
# }
#
# ## Collect the ID of subnet
# data "flexibleengine_vpc_subnet_ids_v1" "subnet_ids" {
#   vpc_id = "${data.flexibleengine_vpc_v1.vpc.id}"
# }


data "flexibleengine_vpc_subnet_v1" "subnet_v1" {
  name   = "${var.subnet_name}"
 }

####

resource "flexibleengine_compute_instance_v2" "basic" {
    name            = "${format("robot-%02d", count.index+1)}"
    image_id        = "${var.win_image}"
    flavor_id       = "${var.win_flavor}"
    key_pair        = "uipath"
    security_groups = ["${var.default_sec_group}"]
    count           = "${var.instance_count}"

    network {
        # uuid        = "${element(data.flexibleengine_vpc_subnet_ids_v1.subnet_ids.id,0)}" ## needs to be a strig not a list of strings
      # uuid        = "${data.flexibleengine_vpc_subnet_ids_v1.subnet_ids.id}"
      uuid = "${data.flexibleengine_vpc_subnet_v1.subnet_v1.id}"
      }
    user_data       = "${element(data.template_file.init.*.rendered, count.index)}"

    }
