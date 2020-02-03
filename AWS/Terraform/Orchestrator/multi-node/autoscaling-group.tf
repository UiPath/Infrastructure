# Create a new EC2 launch configuration to be used with the autoscaling group.
resource "aws_launch_configuration" "uipath_app_launch_config" {
  name_prefix                 = "${var.application}-${var.environment}"
  image_id                    = "${data.aws_ami.server_ami.id}"
  instance_type               = "${var.aws_app_instance_type}"
  key_name                    = "${lookup(var.key_name, var.aws_region)}"
  security_groups             = ["${aws_security_group.uipath_stack.id}"]
  associate_public_ip_address = "${var.associate_public_ip_address}"
  user_data                   = "${data.template_file.init.rendered}"


  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "100"
    delete_on_termination = true
  }
}

# Create the autoscaling group.
resource "aws_autoscaling_group" "uipath_app_autoscaling_group" {
  launch_configuration = "${aws_launch_configuration.uipath_app_launch_config.id}"
  min_size             = "${var.instance_count}"
  max_size             = "20"
  desired_capacity     = "${var.instance_count}"
  target_group_arns    = ["${aws_lb_target_group.UiPath_APPgroup.arn}"]
  health_check_type    = "EC2"

  vpc_zone_identifier = "${data.aws_subnet_ids.private.ids}"

  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity = "1Minute"

  tag {
    key                 = "Name"
    value               = "${var.application}-${var.environment}"
    propagate_at_launch = true
  }
}