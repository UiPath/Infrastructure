### INLINE - W2016 STD UiPath Robot ###
resource "aws_instance" "uirobot_app_server" {
  ami           = "${data.aws_ami.server_ami.image_id}"
  instance_type = "${var.aws_app_instance_type}"
  key_name      = "${lookup(var.key_name, var.aws_region)}"
  user_data     = "${element(data.template_file.init.*.rendered, count.index)}"
  #subnet_id     = "${data.aws_subnet_ids.private.ids}"
  subnet_id     = "${aws_subnet.private[0].id}"
  count         = "${var.instance_count}"
  vpc_security_group_ids = [
    "${aws_security_group.uirobot_stack.id}",
  ]
  #ebs_optimized = true
  ebs_block_device  {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = "${var.disk_size}"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.application}-${var.environment}-${count.index}"
  }

}
