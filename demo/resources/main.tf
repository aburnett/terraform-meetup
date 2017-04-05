provider "aws" {
  # Credentials loaded from AWS_ACCESS_KEY_ID
  # and AWS_SECRET_ACCESS_KEY by default.
  region = "us-east-1"
}

variable "key"{
  description = "Name of an AWS key pair"
}

variable "count" {
  default = 2
}

resource "aws_security_group" "global-ssh" {
  name        = "global-ssh"
  description = "ssh access from anywhere"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "global-egress" {
  name        = "global-egress"
  description = "Allow all outbound traffic"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami           = "ami-acfee4bb"
  instance_type = "t2.micro"
  key_name = "${var.key}"
  availability_zone = "us-east-1a"
  count = 2
  security_groups = [
    "${aws_security_group.global-egress.name}",
    "${aws_security_group.global-ssh.name}",
    "${element(split("/", aws_elb.web.source_security_group), 1)}"
  ]

  tags {
    Name = "btv-code-${count.index}"
    Foo = "bar"
  }

  provisioner "file" {
    destination = "/opt/bitnami/nginx/html/index.html"
    content = <<EOF
<html><body>
<h1>Hello from instance ${count.index}</h1>
</body></html>
EOF

    # The connection block tells our provisioner how to
    # communicate with the resource (instance)
    connection {
      # The default username for our AMI
      user = "ubuntu"
      type = "ssh"
      # The connection will use the local SSH agent for authentication.
    }
  }
}

resource "aws_elb" "web" {
  name               = "btv-code-elb"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  //instances                   = ["${aws_instance.app.*.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "btv-code"
  }
}

resource "aws_elb_attachment" "web_app" {
  count = "${var.count}"
  elb      = "${aws_elb.web.id}"
  instance = "${element(aws_instance.app.*.id, count.index)}"
}