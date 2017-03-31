# First run terraform get to fetch all modules. Must be run whenever a module is updated.

variable "key" {
}
variable "subnet" {}

provider "aws" {
  region = "us-east-1"
}

module "apptastic-green" {
  source = "../modules/apptastic"
  env = "green-staging"
  key = "${var.key}"
  subnet = "${var.subnet}"
}

module "apptastic-blue" {
  source = "../modules/apptastic"
  env = "blue-staging"
  key = "${var.key}"
  subnet = "${var.subnet}"
}

output "CONFIGURATION" {
  value = <<EOF

    Apptastic-${module.apptastic-blue.env} listening on ${module.apptastic-blue.queue}
    Apptastic-${module.apptastic-green.env} listening on ${module.apptastic-green.queue}

EOF
}