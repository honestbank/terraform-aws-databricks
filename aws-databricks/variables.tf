
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

variable "tags" {
  default = {}
}

variable "workspace_name" {
  description = "Name of the workspace"
  default     = "test"
}

variable "role_arn" {
  description = "Role ARN"
}

variable "root_bucket" {
  description = "Root Bucket"
}

variable "private_subnet_ids" {
  description = "Private Subnet IDs"
  type        = set(string)
}

variable "prefix" {
  description = "Prefix for databricks"
}

variable "public_subnet_id" {
  description = "Public Subnet ID"
  type        = string
}
