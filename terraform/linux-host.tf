data "aws_ami" "linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
  owners = ["amazon"]
}

data "aws_ami" "windows" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
  owners = ["amazon"]
}


resource "aws_security_group" "linux_security_group" {
  name_prefix = "linux_hosts_"
  vpc_id      = aws_vpc.core_vpc.id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "windows_security_group" {
  name_prefix = "windows_hosts_"
  vpc_id      = aws_vpc.core_vpc.id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


resource "aws_iam_role" "linux_host_role" {
  name_prefix = "linux_host_role_"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    aws_iam_policy.ssm_policy.arn
  ]
}


resource "aws_iam_role" "windows_host_role" {
  name_prefix = "windows_host_role_"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    aws_iam_policy.ssm_policy.arn
  ]
}

resource "aws_iam_instance_profile" "linux_host_role_instance_profile" {
  role = aws_iam_role.linux_host_role.name
}

resource "aws_iam_instance_profile" "windows_host_role_instance_profile" {
  role = aws_iam_role.windows_host_role.name
}


resource "aws_instance" "linux_instance" {
  ami                  = data.aws_ami.linux.id
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.linux_host_role_instance_profile.id

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.linux_security_group.id]
  subnet_id                   = aws_subnet.core_subnet_a.id
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 10
    volume_type           = "gp2"
  }

  tags = {
    Name = "linux-host"
  }
}

resource "aws_instance" "windows_instance" {
  ami                  = data.aws_ami.windows.id
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.windows_host_role_instance_profile.id

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.windows_security_group.id]
  subnet_id                   = aws_subnet.core_subnet_b.id
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 50
    volume_type           = "gp2"
  }

  tags = {
    Name = "windows-host"
  }
}