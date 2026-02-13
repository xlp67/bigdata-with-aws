variable "project_name" {
  description = "Nome do projeto, usado como prefixo para os recursos."
  type        = string
  default     = "bigdata"
}

variable "aws_region" {
  description = "Região da AWS para a criação dos recursos."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente de deployment (ex: dev, prod)."
  type        = string
}

variable "mwaa_airflow_version" {
  description = "Versão do Airflow para o ambiente MWAA."
  type        = string
  default     = "2.8.1"
}
