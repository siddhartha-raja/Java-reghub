resource "aws_key_pair" "this" {
  key_name   = "${var.project_name}-${terraform.workspace}-key"
  public_key = var.public_key

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${terraform.workspace}-key"
    Environment = terraform.workspace
  })
}