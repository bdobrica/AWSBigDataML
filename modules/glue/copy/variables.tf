variable "name" {
  type = string
  description = "The name of the glue job."
}

variable "script_bucket_name" {
  type = string
  description = "The name of the bucket to store the script of the glue job."
}

variable "script_bucket_key" {
  type = string
  description = "The key from the bucket to store the script of the glue job."
}

variable "script_kms_key" {
  type = string
  description = "The KMS key Arn to encrypt the script of the glue job."
}

variable "source_bucket" {
  type = string
  description = "The name of the bucket from which to copy the data from."
}

variable "source_bucket_key" {
  type = string
  description = "The KMS key Arn used to encrypt the source data."
}

variable "target_bucket" {
  type = string
  description = "The name of the bucket to which to copy the data to."
}

variable "target_bucket_key" {
  type = string
  description = "The KMS key Arn used to encrypt the target data. If missing, the script_bucket_key will be used."
  default = ""
}