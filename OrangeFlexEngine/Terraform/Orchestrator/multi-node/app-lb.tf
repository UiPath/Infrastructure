#### Load balancer
resource "flexibleengine_elb_loadbalancer" "orchestratorlb" {
  name = "uipath"
  type = "External"
  description = "Front Of Orchestrators"
  vpc_id =  "${flexibleengine_vpc_v1.uipath.id}"
  admin_state_up = true
  bandwidth = 100
}

resource "flexibleengine_elb_listener" "listener" {
  name = "uipath-elb-listener"
  description = "uipath listener"
  protocol = "TCP"
  backend_protocol = "TCP"
  protocol_port = 443
  backend_port = 443
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
  healthcheck_protocol = "TCP"
  healthcheck_connect_port = 443
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
