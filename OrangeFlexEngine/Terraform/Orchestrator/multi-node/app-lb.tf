#### Load balancer
resource "flexibleengine_elb_loadbalancer" "orchestratorlb" {
  name = "uipath"
  type = "External"
  description = "Front Of Orchestrators"
  vpc_id =  "${flexibleengine_vpc_v1.uipath.id}"
  admin_state_up = true
  bandwidth = 100
  vip_address = "${var.vip}"
}

resource "flexibleengine_elb_listener" "listener" {
  depends_on=["flexibleengine_elb_loadbalancer.orchestratorlb"]
  name = "uipath-elb-listener"
  description = "uipath listener"
  protocol = "HTTP"
  backend_protocol = "HTTP"
  protocol_port = 80
  backend_port = 80
  lb_algorithm = "roundrobin"
  loadbalancer_id = "${flexibleengine_elb_loadbalancer.orchestratorlb.id}"
  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}

resource "flexibleengine_elb_health" "healthcheck" {
  listener_id = "${flexibleengine_elb_listener.listener.id}"
  healthcheck_protocol = "HTTP"
  healthcheck_connect_port = 80
  healthy_threshold = 5
  healthcheck_timeout = 25
  healthcheck_interval = 3
  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}


### Only 2 hardcoded. TODO - make it dynamically

resource "flexibleengine_elb_backend" "orchestrator-01" {
  address =  "${flexibleengine_compute_instance_v2.basic.0.network.0.fixed_ip_v4}"
  listener_id = "${flexibleengine_elb_listener.listener.id}"
  server_id = "${flexibleengine_compute_instance_v2.basic.0.id}"
  depends_on = ["flexibleengine_compute_instance_v2.basic"]
  }


resource "flexibleengine_elb_backend" "orchestrator-02" {
  address =  "${flexibleengine_compute_instance_v2.basic.1.network.0.fixed_ip_v4}"
  listener_id = "${flexibleengine_elb_listener.listener.id}"
  server_id = "${flexibleengine_compute_instance_v2.basic.1.id}"
  depends_on = ["flexibleengine_compute_instance_v2.basic"]
  }
