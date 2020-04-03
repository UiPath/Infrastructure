
resource "flexibleengine_vpc_v1" "uipath" {
  name = "${var.vpc_name}"
  cidr = "${var.vpc_cidr}"
}


### Uipath subnet
resource "flexibleengine_vpc_subnet_v1" "subnet_uipath" {
  name = "${var.subnet_name}"
  cidr = "${var.subnet_cidr}"
  gateway_ip = "${var.subnet_gateway_ip}"
  vpc_id = "${flexibleengine_vpc_v1.uipath.id}"
  primary_dns = "100.125.0.41"
  secondary_dns = "100.126.0.41"
}
