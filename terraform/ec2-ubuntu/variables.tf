variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used in tags and resource names"
  type        = string
}

variable "environment" {
  description = "Environment name. This can be mapped with Terraform workspace."
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID where EC2 security group will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs where instances will be launched"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 3
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  sensitive   = true
}

variable "public_key" {
  description = "Public SSH key content for EC2 key pair"
  type        = string
  sensitive   = true
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 8
}

variable "additional_volume_size" {
  description = "Additional EBS volume size in GB"
  type        = number
  default     = 10
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}