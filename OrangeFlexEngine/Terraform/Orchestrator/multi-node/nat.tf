resource "flexibleengine_nat_gateway_v2" "nat_uipath" {
  depends_on = ["flexibleengine_vpc_v1.uipath"]
  name   = "Uiptah_Nat_GTW"
  description = "Used to get internet access for VMs"
  spec = "3"
  router_id = "${flexibleengine_vpc_v1.uipath.id}"
  internal_network_id = "${flexibleengine_vpc_subnet_v1.subnet_uipath.id}"
}


resource "flexibleengine_nat_snat_rule_v2" "snat_uipath" {
  nat_gateway_id = "${flexibleengine_nat_gateway_v2.nat_uipath.id}"
  network_id =  "${flexibleengine_vpc_subnet_v1.subnet_uipath.id}"
  floating_ip_id = "87c97b86-d9bd-4102-b6b9-bc3f4baeb4a5"
}
