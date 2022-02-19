resource "aws_glue_job" "copy" {
  name          = var.name
  role_arn      = aws_iam_role.role.arn

  command {
    script_location = "s3://${aws_s3_bucket.example.bucket}/example.py"
  }
}