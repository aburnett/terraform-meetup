variable "key" {
  description = "SSH key for launched instances"
}

variable "env" {
  description = "Environment"
}

variable "asg_min" {
  description = "Min numbers of servers in ASG"
  default     = "0"
}

variable "asg_max" {
  description = "Max numbers of servers in ASG"
  default     = "1"
}

variable "asg_desired" {
  description = "Desired numbers of servers in ASG"
  default     = "0"
}

variable "instance_type" {
  default     = "t2.small"
  description = "AWS instance type"
}

variable "subnet" {
  description = "Comma delimited list of subnets"
}