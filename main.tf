resource "aws_s3_bucket" "pritunlvpn_backup" {
  bucket = var.backup_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_acl" "pritunlvpn_backup" {
  bucket = aws_s3_bucket.pritunlvpn_backup.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "pritunlvpn_backup" {
  bucket = aws_s3_bucket.pritunlvpn_backup.id

  rule {
    id     = "PritunlVPN-Backups-Lifecycle"
    status = "Enabled"

    expiration {
      days = var.backup_file_expiration
    }
  }
}

resource "aws_eip" "pritunlvpn_eip" {
  vpc  = true
  tags = merge(var.tags,
    {
        Name    = "Name"
        Comment = "Managed by Terraform"
    })
}

resource "aws_security_group" "pritunlvpn" {
  name        = "${var.name}-sg"
  description = "Allow PritunlVPN Traffic"
  vpc_id      = data.aws_subnet.vpc_lookup.vpc_id

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = [var.allowed_cidr]
    self        = true
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
    self        = true
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags,
    {
        Name    = "Name"
        Comment = "Managed by Terraform"
    })
}

resource "aws_iam_instance_profile" "main" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name = "${var.name}-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "instance_role_policy" {
  name   = "${var.name}-instance-role-policy"
  role   = aws_iam_role.instance_role.name
  policy = file("${path.module}/instance_policy.json")
}

resource "aws_launch_configuration" "main" {
  name_prefix                 = "${var.name}-lc"
  security_groups             = [aws_security_group.pritunlvpn.id]
  key_name                    = var.key_name
  image_id                    = var.pritunlvpn_ami_map[var.region]
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.main.name
  user_data                   = data.template_file.pritunlvpn_user_data.rendered
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_eip.pritunlvpn_eip]
}

resource "aws_autoscaling_group" "main" {
  name                 = "${var.name}-asg"
  vpc_zone_identifier  = [var.subnet_id]
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.main.name

  lifecycle {
    create_before_destroy = true
  }
}
