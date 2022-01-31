# Databricks module for use with AWS
This module creates a few things:
* Creates route tables
* Creates security groups
* creates nat gateway
* create EIP for nat
* creates internet gateway
* creates VPC endpoints for s3, sts, kinesis-streams

Additionally, it will create credentials for Databricks and a Databricks workspace.

You must have a VPC, 2 private subnets, one public subnet, a role to allow Databricks access, and a bucket for
Databricks to use this module. The subnets must be at least /24.

Additionally, you need a deployment prefix which requires contacting databricks.

example usage:

Setup of policy, role and bucket
```terraform
# policy to attach to role
data "aws_iam_policy_document" "databricks_policy" {
  # checkov:skip=CKV_AWS_111: For test purposes only
  statement {
    effect = "Allow"
    actions = [
      "ec2:AssociateIamInstanceProfile",
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
      "ec2:TerminateInstances"
    ]
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

# Assume role
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
      # databricks aws account (static)
      identifiers = ["arn:aws:iam::414351767826:root"]
    }
  }
}

resource "aws_s3_bucket" "root_bucket" {
  # checkov:skip=CKV_AWS_18: Just for tests
  # checkov:skip=CKV_AWS_144: Just for tests
  # checkov:skip=CKV2_AWS_6: Just for tests
  bucket = "${var.prefix}-databricks-rootbucket-${random_string.naming.result}"
  acl    = "private"

  force_destroy = true

  tags = {
    Name = "${var.prefix}-databricks-rootbucket"
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
```

```terraform
module "aws-databricks" {
  source = "./aws-databricks"

  prefix                      = var.prefix
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
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |
| <a name="requirement_template"></a> [template](#requirement\_template) | ~> 2.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_subnet.subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region | `any` | `null` | no |
| <a name="input_aws_role_arn"></a> [aws\_role\_arn](#input\_aws\_role\_arn) | AWS Role ARN | `any` | `null` | no |
| <a name="input_subnet_cidr"></a> [subnet\_cidr\_block](#input\_subnet\_cidr\_block) | CIDR block for subnet | `string` | `null` | no |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Name for subnet | `string` | `null` | no |
| <a name="input_subnet_tags"></a> [subnet\_tags](#input\_subnet\_tags) | Tags | `map(any)` | <pre>{<br>  "CreatedBy": "terraform-aws-subnet"<br>}</pre> | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_subnet_id"></a> [aws\_subnet\_id](#output\_aws\_subnet\_id) | n/a |
<!-- END_TF_DOCS -->
