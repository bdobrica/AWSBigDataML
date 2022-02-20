variable "name" {
  type = string
  description = "The name of the glue job."
}

variable "loggroup" {
  type = string
  description = "The name of the log group. If missing, it will be the same as the function name."
  default = ""
}

variable "loggroup_retention" {
  type = integer
  description = "The number of days to retain logs in the log group."
  default = 1
}

variable "loggroup_kms_key" {
  type = string
  description = "The KMS key to use for encrypting the log group. If missing, the KMS Key for the script bucket will be used. If disabled is passed, the key will be disabled."
  default = ""
}

variable "script_bucket" {
  type = string
  description = "The name of the bucket to store the script of the glue job."
}

variable "script_key" {
  type = string
  description = "The key from the bucket to store the script of the glue job."
  default = "glue/scripts/proc.py"
}

variable "script_kms_key" {
  type = string
  description = "The KMS key Arn to encrypt the script of the glue job."
}

variable "processor_bucket" {
  type = string
  description = "The name of the bucket to store the processors for the glue job. If missing, script_bucket will be used."
  default = ""
}

variable "processor_key" {
  type = string
  description = "The key from the bucket to store the processors for the glue job."
  default = "glue/processors"
}

variable "processor_kms_key" {
  type = string
  description = "The KMS key Arn to encrypt the processors for the glue job. If missing, the script_kms_key will be used."
  default = ""
}

variable "schema_bucket" {
  type = string
  description = "The name of the bucket to store the schemas for the data processed by the glue jobs. If missing, the script_bucket will be used."
  default = ""
}

variable "schema_key" {
  type = string
  description = "The key from the bucket to store the schemas for the data processed by the glue jobs."
  default = "glue/schemas"
}

variable "schema_kms_key" {
  type = string
  description = "The KMS key Arn to encrypt the schemas for the data processed by the glue jobs. If missing, the script_kms_key will be used."
  default = ""
}

variable "source_bucket" {
  type = string
  description = "The name of the bucket from which to copy the data from."
}

variable "source_kms_key" {
  type = string
  description = "The KMS key Arn used to encrypt the source data."
}

variable "target_bucket" {
  type = string
  description = "The name of the bucket to which to copy the data to."
}

variable "target_kms_key" {
  type = string
  description = "The KMS key Arn used to encrypt the target data. If missing, the script_bucket_key will be used."
  default = ""
}