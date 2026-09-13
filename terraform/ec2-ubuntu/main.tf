locals {
  name_prefix = "${var.project_name}-${terraform.workspace}"

  instances = {
    for index in range(var.instance_count) :
    "instance-${index + 1}" => {
      name      = "${local.name_prefix}-ubuntu-${index + 1}"
      subnet_id = var.subnet_ids[index % length(var.subnet_ids)]
    }
  }
}

resource "aws_security_group" "ec2" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Security group for Ubuntu EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  ingress {
    description = "HTTP access optional"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${local.name_prefix}-ec2-sg"
    Environment = terraform.workspace
  })
}

module "ec2_instances" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  for_each = local.instances

  name = each.value.name

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = file("${path.module}/user_data.sh")

  root_block_device = {
    encrypted  = true
    kms_key_id = aws_kms_key.ebs.arn
    type       = "gp3"
    size       = var.root_volume_size
  }

  ebs_volumes = {
    data = {
      device_name = "/dev/sdf"
      encrypted   = true
      kms_key_id  = aws_kms_key.ebs.arn
      type        = "gp3"
      size        = var.additional_volume_size
      throughput  = 125
      iops        = 3000

      tags = merge(var.common_tags, {
        Name        = "${each.value.name}-data-volume"
        Environment = terraform.workspace
      })
    }
  }

  tags = merge(var.common_tags, {
    Name        = each.value.name
    Environment = terraform.workspace
  })
}