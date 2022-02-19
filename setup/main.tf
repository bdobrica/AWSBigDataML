locals {
  config = jsondecode(file("../config.json"))
  app_namespace = local.config.app_namespace
  environment = local.config.environment
}

#
# Creating the KMS key used to encrypt the resources
#

resource "aws_kms_key" "state_bucket_key" {
  description = "Deployment KMS Key used for encrypting states."
  deletion_window_in_days = 7
  tags = {
    creator = "terraform"
  }
}

#
# Creating and securing the terraform state bucket
#

resource "aws_s3_bucket" "state_bucket" {
  name = "${local.app_namespace}-tf-state-${local.environment}"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.state_bucket_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  tags = {
    creator = "terraform"
  }
}

data "aws_iam_policy_document" "state_bucket_ssl" {
  statement {
      sid = "AllowSSLRequestsOnly"
      actions = "s3:*"
      effect = "Deny"
      resource = [
        aws_s3_bucket.state_bucket.arn,
        "${aws_s3_bucket.state_bucket.arn}/*",
      ]
      condition {
        test = "Bool"
        variable = "aws:SecureTransport"
        values = ["false"]
      }
      principals {
        type = "*"
        identifiers = ["*"]
      }
  }
}

resource "aws_s3_bucket_acl" "state_bucket_acl" {
  bucket = aws_s3_bucket.state_bucket.id
  acl = "private"
}

resource "aws_s3_bucket_policy" "state_bucket_policy" {
  bucket = aws_s3_bucket.state_bucket.id
  policy = data.aws_iam_policy_document.state_bucket_ssl.json
}

#
# The DynamoDB table used to store the state lock
#

resource "aws_dynamodb_table" "state_table" {
  name = "${local.app_namespace}-tf-state-${local.environment}"
  billing_mode = "PAY_PER_REQUEST"
  server_side_encryption {
    enabled = true
    kms_key_id = aws_kms_key.state_bucket_key.arn
  }
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}