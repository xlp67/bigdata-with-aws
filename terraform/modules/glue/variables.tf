variable "project_name" {
  description = "Nome do projeto."
  type        = string
}

variable "environment" {
  description = "Ambiente de deployment."
  type        = string
}

variable "aws_region" {
  description = "Região da AWS."
  type        = string
}

variable "scripts_bucket_id" {
  description = "ID do bucket S3 que armazena os scripts do Glue."
  type        = string
}

variable "raw_bucket_arn" {
  description = "ARN do bucket S3 de dados brutos."
  type        = string
}

variable "processed_bucket_arn" {
  description = "ARN do bucket S3 de dados processados."
  type        = string
}

variable "common_tags" {
  description = "Tags comuns para os recursos."
  type        = map(string)
  default     = {}
}
