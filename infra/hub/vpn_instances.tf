resource "aws_instance" "openvpn_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.hub.key_name
  subnet_id     = aws_subnet.hub[0].id

  vpc_security_group_ids = [aws_security_group.openvpn_sg.id]

  user_data = base64encode(file("${path.module}/scripts/openvpn-setup.sh"))

  tags = {
    Name = "${local.hub_name_prefix}-openvpn-server"
  }
}

resource "aws_eip" "openvpn_eip" {
  instance = aws_instance.openvpn_server.id
  domain   = "vpc"

  tags = {
    Name = "${local.hub_name_prefix}-openvpn-eip"
  }
}

# Security Group for OpenVPN Server
resource "aws_security_group" "openvpn_sg" {
  name        = "${local.hub_name_prefix}-openvpn-security-group"
  description = "Security group for OpenVPN server"
  vpc_id      = aws_vpc.hub.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.hub_name_prefix}-openvpn-security-group"
  }
}

# Key Pair for SSH access
resource "aws_key_pair" "hub" {
  key_name   = "hub_key"
  public_key = local.hub_public_key
}

# Data source for Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
