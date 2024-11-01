data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

resource "aws_key_pair" "core_key" {
  key_name   = "core_key"
  public_key = file("${path.cwd}/pub_keys/${terraform.workspace}_hub_instance_access.pub")
  tags = {
    Name = "${local.core_name_prefix}-instance-access"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.core.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "public" {
  count                       = local.core_az_count
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = "t2.nano"
  subnet_id                   = aws_subnet.core_public[count.index].id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true

  key_name = aws_key_pair.core_key.key_name

  tags = {
    Name = "${local.core_name_prefix}-ec2-public-${count.index}"
  }
}

resource "aws_instance" "private" {
  count                  = local.core_az_count
  ami                    = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type          = "t2.nano"
  subnet_id              = aws_subnet.core_private[count.index].id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  key_name = aws_key_pair.core_key.key_name

  tags = {
    Name = "${local.core_name_prefix}-ec2-private-${count.index}"
  }
}
