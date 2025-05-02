#Load AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

#Create the main backup vault using specific KMS key
resource "aws_backup_vault" "main" {
  name        = "main-backup-vault"
  kms_key_arn = var.kms_key_arn
}

#Setup the WORM protection
resource "aws_backup_vault_lock_configuration" "lock" {
  backup_vault_name     = aws_backup_vault.main.name
  changeable_for_days   = 0
  min_retention_days    = 7
  max_retention_days    = 1200
}

#Daily Backup plan with 365 days retention with copy to another region & aws account
resource "aws_backup_plan" "main" {
  name = "daily-backup-plan"

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 * * * *)"

    lifecycle {
      delete_after = 365
    }

    copy_action {
      destination_vault_arn = var.cross_region_vault_arn
      lifecycle {
        delete_after = 365
      }
    }

    copy_action {
      destination_vault_arn = var.cross_account_vault_arn
      target_kms_key_arn = var.cross_account_kms_key_arn
      lifecycle {
        delete_after = 365
      }
    }
  }
}

#Select resources to backup based on custom tags
resource "aws_backup_selection" "selection" {
  iam_role_arn = var.backup_role_arn
  name         = "tag-based-backup"
  plan_id      = aws_backup_plan.main.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "ToBackup"
    value = "true"
  }

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Owner"
    value = var.owner_email #owner@eulerhermes.com.com
  }
}

#Variables to be set in a separate tfvars file
variable "aws_region" {}
variable "kms_key_arn" {}
variable "cross_region_vault_arn" {}
variable "cross_account_vault_arn" {}
variable "backup_role_arn" {}