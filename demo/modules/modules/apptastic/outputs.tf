output "queue" {
  value = "${aws_sqs_queue.work_queue.arn}"
}

output "env" {
  value = "${var.env}"
}