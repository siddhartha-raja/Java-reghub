resource "aws_kms_key" "ebs" {
  description             = "KMS key for encrypted EBS volumes - ${var.project_name}-${terraform.workspace}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${terraform.workspace}-ebs-kms"
    Environment = terraform.workspace
  })
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.project_name}-${terraform.workspace}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}