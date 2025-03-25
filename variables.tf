variable "name" {
  description = "The name to use for resources. Defaults to bastion"
  default     = "bastion"
  type        = string
}

variable "vpc_id" {
  description = "The VPC to launch in"
  type        = string
}

variable "subnet_id" {
  description = "The subnet to launch the instance into"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instance to run"
  type        = string

  default = "t4g.micro"
}

