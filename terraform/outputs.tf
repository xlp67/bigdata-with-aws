# Outputs do Módulo S3
output "raw_bucket_id" {
  description = "ID do bucket S3 para dados brutos."
  value       = module.s3.raw_bucket_id
}

output "processed_bucket_id" {
  description = "ID do bucket S3 para dados processados."
  value       = module.s3.processed_bucket_id
}

output "scripts_bucket_id" {
  description = "ID do bucket S3 para scripts do Glue."
  value       = module.s3.scripts_bucket_id
}

output "dags_bucket_id" {
  description = "ID do bucket S3 para DAGs do MWAA."
  value       = module.s3.dags_bucket_id
}

# Outputs do Módulo Glue
output "glue_job_name" {
  description = "Nome do Job do AWS Glue criado."
  value       = module.glue.glue_job_name
}

# Outputs do Módulo MWAA
output "mwaa_environment_name" {
  description = "Nome do ambiente MWAA."
  value       = module.mwaa.mwaa_environment_name
}

output "mwaa_airflow_url" {
  description = "URL da UI do Airflow."
  value       = module.mwaa.mwaa_airflow_url
  sensitive   = true
}
