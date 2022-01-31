terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
}


provider "aws" {
  region = var.aws_region
  alias  = "target"
  assume_role {
    role_arn = var.aws_role_arn
  }
}

locals {
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

resource "aws_vpc" "main" {
  #checkov:skip=CKV2_AWS_11:No resources
  #checkov:skip=CKV2_AWS_12:No resources
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "honest-databricks"
  }
}

module "subnet" {
  count             = length(var.subnet_cidr_blocks)
  source            = "github.com/honestbank/terraform-aws-subnet/aws-subnet"
  subnet_cidr_block = var.subnet_cidr_blocks[count.index]
  vpc_id            = aws_vpc.main.id
  subnet_name       = "honest-subnet-databricks-${count.index}"
  subnet_tags       = {}
  depends_on        = [aws_vpc.main]
  subnet_az         = local.availability_zones[count.index]
}

module "public_subnet" {
  source            = "github.com/honestbank/terraform-aws-subnet/aws-subnet"
  subnet_cidr_block = var.public_subnet_cidr_block
  vpc_id            = aws_vpc.main.id
  subnet_name       = "honest-subnet-databricks-public"
  subnet_tags       = {}
  depends_on        = [aws_vpc.main]
}

output "private_subnet_ids" {
  value = [for s in module.subnet : s.aws_subnet_id]
}

output "public_subnet_id" {
  value = module.public_subnet.aws_subnet_id
}

output "vpc_id" {
  value = aws_vpc.main.id
}
