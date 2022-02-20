resource "aws_s3_bucket_object" "script" {
  bucket = var.script_bucket_name
  key = var.script_bucket_key
  kms_key_id = var.script_kms_key
  source = "{path.module}/scripts/copy.py"
  etag = filemd5("{path.module}/scripts/copy.py")
}