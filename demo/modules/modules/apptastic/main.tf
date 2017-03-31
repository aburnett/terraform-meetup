resource "aws_sqs_queue" "work_queue" {
  name                      = "apptastic-${var.env}"
}

resource "aws_autoscaling_policy" "increase-processing" {
  name                   = "IncreaseApptasticProcessing-${var.env}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 360
  autoscaling_group_name = "${aws_autoscaling_group.apptastic.name}"
}

resource "aws_autoscaling_policy" "decrease-processing" {
  name                   = "DecreaseApptasticProcessing-${var.env}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 360
  autoscaling_group_name = "${aws_autoscaling_group.apptastic.name}"
}

resource "aws_cloudwatch_metric_alarm" "add-capacity" {
  alarm_name          = "AddCapacityForApptastic-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "3"

  dimensions {
    QueueName = "${aws_sqs_queue.work_queue.name}"
  }

  alarm_actions     = ["${aws_autoscaling_policy.increase-processing.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "remove-capacity" {
  alarm_name          = "AddCapacityForApptastic-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"

  dimensions {
    QueueName = "${aws_sqs_queue.work_queue.name}"
  }

  alarm_actions     = ["${aws_autoscaling_policy.decrease-processing.arn}"]
}

resource "aws_autoscaling_group" "apptastic" {
  name                 = "Apptastic-${var.env}"
  max_size             = "${var.asg_max}"
  min_size             = "${var.asg_min}"
  desired_capacity     = "${var.asg_desired}"
  force_delete         = true
  launch_configuration = "${aws_launch_configuration.apptastic.name}"
  vpc_zone_identifier  = ["${split(",", var.subnet)}"]

  tag {
    key                 = "Name"
    value               = "Apptastic-${var.env}"
    propagate_at_launch = "true"
  }
}

data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_configuration" "apptastic" {
  # Don't specify a name here so terraform can safely update the launch config
  image_id             = "${data.aws_ami.app_ami.id}"
  instance_type        = "${var.instance_type}"
  enable_monitoring    = false

  # Security group
  key_name        = "${var.key}"

  lifecycle {
    create_before_destroy = true
  }
}