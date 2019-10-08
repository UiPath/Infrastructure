resource "aws_acm_certificate" "wildcard-certificate" {
  count = "${length(var.certificate_arn) < 1  ? 1 : 0}"
  domain_name               = "${var.subdomain}.${var.domain}"
  subject_alternative_names = ["*.${var.subdomain}.${var.domain}"]
  validation_method         = "DNS"
  tags ={
    Name = "${var.domain}"
  }
}
resource "aws_route53_record" "wildcard-certificate-validation" {
  count = "${length(var.certificate_arn) < 1  ? 1 : 0}"
  name    = "${aws_acm_certificate.wildcard-certificate[0].domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.wildcard-certificate[0].domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.domain.id}"
  records = ["${aws_acm_certificate.wildcard-certificate[0].domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}
resource "aws_acm_certificate_validation" "wildcard-certificate" {
  count = "${length(var.certificate_arn) < 1  ? 1 : 0}"
  certificate_arn         = "${aws_acm_certificate.wildcard-certificate[0].arn}"
  validation_record_fqdns = ["${aws_route53_record.wildcard-certificate-validation[0].fqdn}"]
}