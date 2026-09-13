output "instance_ids" {
  description = "Created EC2 instance IDs"
  value = {
    for key, instance in module.ec2_instances :
    key => instance.id
  }
}

output "public_ips" {
  description = "Public IPs of EC2 instances"
  value = {
    for key, instance in module.ec2_instances :
    key => instance.public_ip
  }
}

output "private_ips" {
  description = "Private IPs of EC2 instances"
  value = {
    for key, instance in module.ec2_instances :
    key => instance.private_ip
  }
}

output "key_pair_name" {
  description = "EC2 key pair name"
  value       = aws_key_pair.this.key_name
}

output "kms_key_arn" {
  description = "KMS key ARN for EBS encryption"
  value       = aws_kms_key.ebs.arn
}