# Databricks module for use with AWS
See documentation here: [aws-databricks/README.md](aws-databricks/README.md)


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.74.3 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws-databricks"></a> [aws-databricks](#module\_aws-databricks) | ./aws-databricks | n/a |
| <a name="module_databricks_policy"></a> [databricks\_policy](#module\_databricks\_policy) | ./modules/terraform-aws-iam/aws-iam/policy | n/a |
| <a name="module_databricks_role"></a> [databricks\_role](#module\_databricks\_role) | ./modules/terraform-aws-iam/aws-iam/role | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.root_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [random_string.naming](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.databricks_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region | `any` | `null` | no |
| <a name="input_aws_role_arn"></a> [aws\_role\_arn](#input\_aws\_role\_arn) | AWS Role ARN | `any` | `null` | no |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks Account ID | `any` | n/a | yes |
| <a name="input_databricks_account_password"></a> [databricks\_account\_password](#input\_databricks\_account\_password) | Databricks Account Password | `any` | n/a | yes |
| <a name="input_databricks_account_username"></a> [databricks\_account\_username](#input\_databricks\_account\_username) | Databricks Account Username | `any` | n/a | yes |
| <a name="input_enable_kinesis"></a> [enable\_kinesis](#input\_enable\_kinesis) | Enable Kinesis for use with databricks (alternatively, you can use apache kafka) | `bool` | `false` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for databricks which is required so databricks can see resources. Can be prefixed as `prefix-someotherstring` | `any` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private Subnet IDs used for databricks to know where to deploy ec2 instances | `set(string)` | n/a | yes |
| <a name="input_public_subnet_id"></a> [public\_subnet\_id](#input\_public\_subnet\_id) | Public Subnet ID used for creating igw | `string` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for VPC | `any` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `any` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
