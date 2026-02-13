variable "project_name" {
  description = "Nome do projeto para prefixar os nomes dos buckets."
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, prod) para sufixar os nomes dos buckets."
  type        = string
}

variable "common_tags" {
  description = "Tags comuns a serem aplicadas nos buckets."
  type        = map(string)
  default     = {}
}
