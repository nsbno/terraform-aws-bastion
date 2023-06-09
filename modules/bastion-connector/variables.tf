variable "bastion_security_group_id" {
  description = "The bastion host's security group id"
  type        = string
}

variable "target_security_group_id" {
  description = "The security group that the bastion will be able to access"
  type        = string
}

variable "port" {
  description = "The port the connection will use"
  type        = number
}

variable "protocol" {
  description = "The protocol the connection will use"
  type        = string

  default = "tcp"
}
