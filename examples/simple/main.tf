data "aws_vpc" "this" {
  tags = {
    Name = "shared"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    Tier = "Private"
  }
}

module "bastion" {
  source = "../../"

  vpc_id    = data.aws_vpc.this.id
  subnet_id = data.aws_subnets.private.ids[0]
}

# To allow the bastion to connect to your database for example, you need to connect them.
data "aws_security_group" "database" {
  name   = "database"
  vpc_id = data.aws_vpc.this.id
}

module "bastion_to_database" {
  source = "../../modules/bastion-connector"

  bastion_security_group_id = module.bastion.security_group_id
  target_security_group_id  = data.aws_security_group.database.id

  port = 5432
}
