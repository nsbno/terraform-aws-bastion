/*
 * = Role
 */
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

resource "aws_iam_role" "this" {
  name               = "bastion"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.ssm_managed_instance.arn
}

/*
 * = Networking
 */
resource "aws_security_group" "this" {
  name   = "bastion"
  vpc_id = var.vpc_id
}

/*
 * = Instance Setup
 */
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }
}

resource "aws_iam_instance_profile" "this" {
  name = "bastion"
  role = aws_iam_role.this.name
}

resource "aws_instance" "this" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.this.name

  tags = {
    Name = "bastion"
  }
}
