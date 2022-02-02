variable "vpc_id" {
  description = "VPC ID"
  default     = null
}

variable "aws_region" {
  description = "AWS Region"
  default     = null
}

variable "databricks_account_username" {
  description = "Databricks Account Username"
}
variable "databricks_account_password" {
  description = "Databricks Account Password"
}
variable "databricks_account_id" {
  description = "Databricks Account ID"
}

variable "workspace_name" {
  description = "Name of the workspace"
}

variable "role_arn" {
  description = "Role ARN used to assume role to create resources (otherwise uses direct account access)"
  default     = null
}

variable "root_bucket" {
  description = "Root Bucket used solely for databricks. We have no control over this"
}

variable "private_subnet_ids" {
  description = "Private Subnet IDs used for databricks to know where to deploy ec2 instances"
  type        = set(string)
}

variable "prefix" {
  description = "Prefix for databricks which is required so databricks can see resources. Can be prefixed as `prefix-someotherstring`"
}

variable "public_subnet_id" {
  description = "Public Subnet ID used for creating igw"
  type        = string
}
