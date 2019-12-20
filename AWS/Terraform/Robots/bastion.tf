resource "aws_instance" "bastion" {
  ami           = "${data.aws_ami.server_ami.image_id}"
  instance_type = "${var.aws_app_instance_type}"
  subnet_id     = "${aws_subnet.public[0].id}"
  vpc_security_group_ids = [
    "${aws_security_group.uirobot_stack.id}",
  ]
  associate_public_ip_address = true
  key_name                    = "${lookup(var.key_name, var.aws_region)}"

  user_data = "${data.template_file.bastion.rendered}"

  tags = {
    Name = "${var.application}-${var.environment}-BastionHost"
  }
}