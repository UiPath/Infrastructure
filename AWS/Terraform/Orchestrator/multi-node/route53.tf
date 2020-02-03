data "aws_route53_zone" "domain" {
  name = "${var.domain}"
  private_zone = false
}

# Adding a DNS A record for the load balancer
resource "aws_route53_record" "alb" {
  zone_id = "${data.aws_route53_zone.domain.zone_id}"
  name    = "${var.subdomain}.${var.domain}"
  type    = "A"
  alias {
    name                   = "${aws_lb.UiPath_ALB.dns_name}"
    zone_id                = "${aws_lb.UiPath_ALB.zone_id}"
    evaluate_target_health = false
  }
}
