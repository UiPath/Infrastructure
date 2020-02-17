resource "aws_instance" "bastion" {
  ami           = "${data.aws_ami.server_ami.image_id}"
  instance_type = "m4.xlarge"
  subnet_id     = "${aws_subnet.public[0].id}"
  vpc_security_group_ids = [
    "${aws_security_group.uipath_stack.id}",
  ]
  associate_public_ip_address = true
  key_name                    = "${lookup(var.key_name, var.aws_region)}"

  user_data = "${data.template_file.bastion.rendered}"

  tags = {
    Name = "${var.application}-${var.environment}-BastionHost"
  }
}

output "bastion_public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}
