locals {
  name                = var.name
  loggroup            = var.loggroup == "" ? var.name : var.loggroup
  loggroup_retention  = var.loggroup_retention
  loggroup_kms_key    = var.loggroup_kms_key == "" ? local.scratch_kms_key : var.loggroup_kms_key
  script_bucket       = var.script_bucket
  script_key          = var.script_key
  script_kms_key      = var.script_kms_key
  mapping_bucket      = var.mapping_bucket == "" ? local.script_bucket : var.mapping_bucket
  mapping_key         = var.mapping_key
  mapping_kms_key     = var.mapping_kms_key == "" ? local.script_kms_key : var.mapping_kms_key
  schema_bucket       = var.schema_bucket == "" ? local.script_bucket : var.schema_bucket
  schema_key          = var.schema_key
  schema_kms_key      = var.schema_kms_key == "" ? local.script_kms_key : var.schema_kms_key
  target_bucket       = var.target_bucket
  target_kms_key      = var.target_kms_key
}


resource "aws_glue_job" "copy" {
  name                = local.name
  role_arn            = aws_iam_role.role.arn

  command {
    script_location   = "s3://${local.script_bucket}/${local.script_key}"
  }

  default_arguments = {
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.loggroup.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--SOURCE_BUCKET"                    = "${local.source_bucket}"
    "--MAPPINGS_BUCKET"                  = "${local.mapping_bucket}"
    "--MAPPINGS_KEY"                     = "${local.mapping_key}"
    "--SCHEMA_BUCKET"                    = "${local.schema_bucket}"
    "--SCHEMA_KEY"                       = "${local.schema_key}"
    "--TARGET_BUCKET"                    = "${local.target_bucket}"
  }
}