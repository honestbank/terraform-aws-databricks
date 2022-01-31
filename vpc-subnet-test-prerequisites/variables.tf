variable "vpc_cidr" {
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR block for subnet"
  type        = list(string)
  default     = []
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  default     = null
}

variable "aws_role_arn" {
  description = "AWS Role ARN"
  default     = null
}
