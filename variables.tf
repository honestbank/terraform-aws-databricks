variable "vpc_id" {
  description = "VPC ID"
  default     = null
}

variable "aws_region" {
  description = "AWS Region"
  default     = null
}

variable "aws_role_arn" {
  description = "AWS Role ARN"
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
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

variable "private_subnet_ids" {
  description = "Private Subnet IDs used for databricks to know where to deploy ec2 instances"
  type        = set(string)
}

variable "public_subnet_id" {
  description = "Public Subnet ID used for creating igw"
  type        = string
}

variable "prefix" {
  description = "Prefix for databricks which is required so databricks can see resources. Can be prefixed as `prefix-someotherstring`"
}
