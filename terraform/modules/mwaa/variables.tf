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

variable "dags_bucket_id" {
  description = "ID do bucket S3 que armazena as DAGs."
  type        = string
}

variable "airflow_version" {
  description = "Versão do Airflow a ser usada no MWAA."
  type        = string
  default     = "2.8.1"
}

variable "glue_job_arn" {
  description = "ARN do job do Glue que será acionado pelo Airflow."
  type        = string
}

variable "common_tags" {
  description = "Tags comuns para os recursos."
  type        = map(string)
  default     = {}
}
