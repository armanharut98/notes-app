resource "aws_instance" "runner" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.hub.key_name
  subnet_id              = aws_subnet.hub[0].id
  vpc_security_group_ids = [aws_security_group.github_runner_sg.id]
  user_data = base64encode(templatefile("${path.module}/scripts/github_runner_setup.sh", {
    github_token = locals.github_token,
    runner_label = locals.runner_label,
    repo_url     = locals.repo_url
  }))
  user_data_replace_on_change = true
  associate_public_ip_address = true
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      ami,
      associate_public_ip_address
    ]
  }
  tags = {
    Name = "${local.hub_name_prefix}-github-runner"
  }
}

resource "aws_security_group" "github_runner_sg" {
  name        = "${local.hub_name_prefix}-github-runner-sg"
  description = "Security group for Github runners."
  vpc_id      = aws_vpc.hub.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.hub_name_prefix}-github-runner-sg"
  }
}

resource "aws_iam_role" "runner_role" {
  name = locals.ec2_runner_iam_role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${locals.github_org}/${locals.github_repo_name}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "runner_policy" {
  name        = "runner-policy"
  path        = "/"
  description = "Policy for Github EC2 runners"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "runner_policy_attachment" {
  role       = aws_iam_role.runner_role.name
  policy_arn = aws_iam_policy.runner_policy.arn
}

resource "aws_iam_instance_profile" "runner_profile" {
  name = "runner-ec2-profile"
  role = aws_iam_role.runner_role.name
}



