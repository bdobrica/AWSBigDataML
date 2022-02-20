data "aws_partition" "current" {}

resource "aws_iam_role" "role" {
  name = "${local.name}-role"
  assume_role_policy = file("${path.module}/policies/assume_role_policy.json")
}

resource "aws_iam_role_policy" "policy" {
  name = "${var.name}-role-policy"
  role = aws_iam_role.role.id
  policy = templatefile("${path.module}/policies/role_policy.json", {
    loggroup = aws_cloudwatch_log_group.loggroup.arn
    read_only_buckets = distinct([
      "arn:${data.aws_partition.current.partition}:s3:::${local.source_bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${local.mappings_bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${local.schema_bucket}",
    ]),
    read_only_kms_keys = distinct([
      local.source_kms_key,
      local.mappings_kms_key,
      local.schema_kms_key
    ]),
    write_buckets = distinct([
      "arn:${data.aws_partition.current.partition}:s3:::${local.target_bucket}",
    ]),
    write_kms_keys = distinct([
      local.target_kms_key,
      local.loggroup_kms_key
    ])
  })
}