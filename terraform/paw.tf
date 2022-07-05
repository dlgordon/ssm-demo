# In this case, its a Windows PAW
# Install-WindowsFeature RSAT-ADDS

resource "aws_security_group" "paw_security_group" {
  name_prefix = "paw_"
  vpc_id      = aws_vpc.core_vpc.id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Allow access within this security group
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    self             = true
  }
}

resource "aws_iam_role" "paw_host_role" {
  name_prefix = "paw_host_role_"
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

resource "aws_iam_instance_profile" "paw_host_role_instance_profile" {
  role = aws_iam_role.paw_host_role.name
}

resource "aws_launch_template" "paw_launch_template" {
  name_prefix = "paw_launchtemplate_"
  iam_instance_profile {
    name = aws_iam_instance_profile.paw_host_role_instance_profile.id
  }
  image_id                             = data.aws_ami.windows.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "t3.micro"
  network_interfaces {
    associate_public_ip_address = true

    security_groups = [aws_security_group.paw_security_group.id]

  }



  user_data = filebase64("${path.module}/paw.userdata")
}

resource "aws_autoscaling_group" "paw_asg" {
  name_prefix      = "paw_asg_"
  desired_capacity = 0
  max_size         = 0
  min_size         = 0

  launch_template {
    id      = aws_launch_template.paw_launch_template.id
    version = "$Latest"

  }

  vpc_zone_identifier = [aws_subnet.core_subnet_a.id, aws_subnet.core_subnet_b.id, ]

}