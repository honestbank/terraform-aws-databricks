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
  default     = "10.0.0.0/16"
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
  description = "Private Subnet"
  type        = list(string)
}

variable "public_subnet_id" {
  description = "Public Subnet"
}

variable "prefix" {
  description = "Prefix for cluster name"
}
