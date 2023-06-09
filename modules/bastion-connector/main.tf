resource "aws_security_group_rule" "bastion_to_database" {
  security_group_id = var.bastion_security_group_id

  source_security_group_id = var.target_security_group_id

  type = "egress"

  protocol  = var.protocol
  from_port = var.port
  to_port   = var.port
}

resource "aws_security_group_rule" "database_from_bastion" {
  security_group_id = var.target_security_group_id

  source_security_group_id = var.bastion_security_group_id

  type = "ingress"

  protocol  = var.protocol
  from_port = var.port
  to_port   = var.port
}
