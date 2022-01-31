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
  prefix             = var.prefix
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      values   = [var.databricks_account_id]
      variable = "sts:ExternalId"
    }
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::414351767826:root"]
    }
  }
}

data "aws_iam_policy_document" "databricks_policy" {
  # checkov:skip=CKV_AWS_111: ADD REASON
  statement {
    effect = "Allow"
    actions = ["ec2:AssociateIamInstanceProfile",
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CancelSpotInstanceRequests",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteTags",
      "ec2:DeleteVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeIamInstanceProfileAssociations",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstances",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNatGateways",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribePrefixLists",
      "ec2:DescribeReservedInstancesOfferings",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcs",
      "ec2:DetachVolume",
      "ec2:DisassociateIamInstanceProfile",
      "ec2:ReplaceIamInstanceProfileAssociation",
      "ec2:RequestSpotInstances",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RunInstances",
    "ec2:TerminateInstances"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole", "iam:PutRolePolicy"]
    resources = ["arn:aws:iam::*:role/aws-service-role/spot.amazonaws.com/AWSServiceRoleForEC2Spot"]
    condition {
      test     = "StringLike"
      values   = ["ec2.amazonaws.com"]
      variable = "iam:AWSServiceName"
    }
  }
}

module "databricks_policy" {
  source     = "github.com/honestbank/terraform-aws-iam/aws-iam/policy"
  aws_region = var.aws_region
  policy = {
    name        = "${local.prefix}-policy"
    path        = "/"
    description = "Databricks policy"
    policy      = data.aws_iam_policy_document.databricks_policy.json
    tags        = {}
  }
}



module "databricks_role" {
  source     = "github.com/honestbank/terraform-aws-iam/aws-iam/role"
  aws_region = var.aws_region
  role = {
    name               = "${local.prefix}-crossaccount"
    path               = "/"
    description        = "Databricks role"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
    policies           = [module.databricks_policy.policy_arn]
    #policies           = []
    tags = {}
  }
}



#tfsec:ignore:aws-s3-block-public-acls tfsec:ignore:aws-s3-block-public-policy tfsec:ignore:aws-s3-ignore-public-acls tfsec:ignore:aws-s3-no-public-buckets tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-specify-public-access-block
resource "aws_s3_bucket" "root_bucket" {
  # checkov:skip=CKV_AWS_18: ADD REASON
  # checkov:skip=CKV_AWS_144: ADD REASON
  # checkov:skip=CKV2_AWS_6: ADD REASON
  bucket = "${local.prefix}-rootbucket-${random_string.naming.result}"
  acl    = "private"

  force_destroy = true

  tags = {
    Name = "${local.prefix}-rootbucket"
  }
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

module "aws-databricks" {
  source = "./aws-databricks"

  prefix                      = local.prefix
  workspace_name              = "test-lab-networking"
  databricks_account_username = var.databricks_account_username
  databricks_account_password = var.databricks_account_password
  databricks_account_id       = var.databricks_account_id

  role_arn   = module.databricks_role.role_arn
  aws_region = var.aws_region

  root_bucket = aws_s3_bucket.root_bucket.id
  vpc_id      = var.vpc_id

  private_subnet_ids = var.private_subnet_ids

  public_subnet_id = var.public_subnet_id
}
