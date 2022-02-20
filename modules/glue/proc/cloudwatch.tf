resource "aws_cloudwatch_log_group" "loggroup" {
  name = local.loggroup
  retention_in_days = local.loggroup_retention
  kms_key_id = local.loggroup_kms_key == "disabled" ? null : local.loggroup_kms_key

  tags = {
  }
}