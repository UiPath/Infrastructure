resource "aws_autoscaling_policy" "orchestrator-scale-up" {
    name = "Orchestrator-scale-up"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.uipath_app_autoscaling_group.name}"
}

resource "aws_autoscaling_policy" "orchestrator-scale-down" {
    name = "Orchestrator-scale-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.uipath_app_autoscaling_group.name}"
}


resource "aws_cloudwatch_metric_alarm" "memory-high" {
    alarm_name = "mem-util-high-orchestrator"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "Windows/Default"
    period = "300"
    statistic = "Average"
    threshold = "80"
    alarm_description = "This metric monitors ec2 memory for high utilization on Orchestrator hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.orchestrator-scale-up.arn}"
    ]
    dimensions ={
        AutoScalingGroupName = "${aws_autoscaling_group.uipath_app_autoscaling_group.name}"
    }
}

resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name = "mem-util-low-orchestrator"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "Windows/Default"
    period = "300"
    statistic = "Average"
    threshold = "40"
    alarm_description = "This metric monitors ec2 memory for low utilization on Orchestrator  hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.orchestrator-scale-down.arn}"
    ]
    dimensions ={
        AutoScalingGroupName = "${aws_autoscaling_group.uipath_app_autoscaling_group.name}"
    }
}

resource "aws_cloudwatch_metric_alarm" "cpu-high" {
    alarm_name = "cpu-util-high-orchestrator"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "60"
    alarm_description = "This metric monitors ec2 cpu for high utilization on Orchestrator hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.orchestrator-scale-up.arn}"
    ]
    dimensions ={
        AutoScalingGroupName = "${aws_autoscaling_group.uipath_app_autoscaling_group.name}"
    }
}

resource "aws_cloudwatch_metric_alarm" "cpu-low" {
    alarm_name = "cpu-util-low-orchestrator"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "10"
    alarm_description = "This metric monitors ec2 cpu for low utilization on Orchestrator  hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.orchestrator-scale-down.arn}"
    ]
    dimensions ={
        AutoScalingGroupName = "${aws_autoscaling_group.uipath_app_autoscaling_group.name}"
    }
}