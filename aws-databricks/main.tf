terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    databricks = {
      source  = "databrickslabs/databricks"
      version = "0.4.6"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
  }
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

locals {
  prefix = var.prefix
}

###############################################################################
#
# Databricks provider
#
###############################################################################

provider "databricks" {
  alias    = "mws"
  host     = "https://accounts.cloud.databricks.com"
  username = var.databricks_account_username
  password = var.databricks_account_password
}

resource "databricks_mws_credentials" "creds" {
  provider         = databricks.mws
  account_id       = var.databricks_account_id
  role_arn         = var.role_arn
  credentials_name = "${local.prefix}-creds"
}

################################################################################
#
# Databricks Storage
#
################################################################################

resource "databricks_mws_storage_configurations" "root_storage" {
  provider                   = databricks.mws
  account_id                 = var.databricks_account_id
  bucket_name                = var.root_bucket
  storage_configuration_name = "${local.prefix}-storage"
}

################################################################################
#
# Databricks Networking
#
################################################################################

resource "databricks_mws_networks" "vpc_network" {
  provider           = databricks.mws
  account_id         = var.databricks_account_id
  network_name       = "${local.prefix}-network"
  security_group_ids = [aws_security_group.databricks_sg.id]
  subnet_ids         = var.private_subnet_ids
  vpc_id             = var.vpc_id
}

################################################################################
#
# Databricks Workspace
#
################################################################################

resource "null_resource" "previous" {}

resource "time_sleep" "wait" {
  create_duration = "30s"
}

resource "databricks_mws_workspaces" "workspace" {
  provider        = databricks.mws
  account_id      = var.databricks_account_id
  aws_region      = var.aws_region
  workspace_name  = "${local.prefix}-${var.workspace_name}"
  deployment_name = "${local.prefix}-deployment"

  credentials_id           = databricks_mws_credentials.creds.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.root_storage.storage_configuration_id
  network_id               = databricks_mws_networks.vpc_network.network_id

  depends_on = [time_sleep.wait]
  token {
    comment = "Terraform"
  }
}
