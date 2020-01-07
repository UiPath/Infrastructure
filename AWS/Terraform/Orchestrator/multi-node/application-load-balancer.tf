resource "aws_lb" "UiPath_ALB" {
  name            = "UiPathStack-ALB"
  load_balancer_type = "application"
  internal        = false
  security_groups = ["${aws_security_group.uipath_stack.id}"]
  subnets         = "${data.aws_subnet_ids.public.ids}"


}

resource "aws_lb_target_group" "UiPath_APPgroup" {
  name     = "UiPathStack-ALB-target"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = "${aws_vpc.uipath.id}"
  stickiness {
    type = "lb_cookie"
  }
  #target_type = "ip"
  health_check {
    path = "/api/status"
    port = 80
  }
}

# resource "aws_lb_listener" "listener_http" {
#   load_balancer_arn = "${aws_lb.UiPath_ALB.arn}"
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     target_group_arn = "${aws_lb_target_group.UiPath_APPgroup.arn}"
#     type             = "forward"
#   }
# }

resource "aws_lb_listener" "listener_https" {
  depends_on                = ["aws_acm_certificate.wildcard-certificate[0]","var.certificate_arn"]
  load_balancer_arn = "${aws_lb.UiPath_ALB.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${length(var.certificate_arn) < 1  ? aws_acm_certificate.wildcard-certificate[0].arn : var.certificate_arn }"
  default_action {
    target_group_arn = "${aws_lb_target_group.UiPath_APPgroup.arn}"
    type             = "forward"
  }
}


# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "mainLBtargetGroup" {
  depends_on                = ["aws_autoscaling_group.uipath_app_autoscaling_group"]
  autoscaling_group_name = "${aws_autoscaling_group.uipath_app_autoscaling_group.id}"
   alb_target_group_arn   = "${aws_lb_target_group.UiPath_APPgroup.arn}"
}



