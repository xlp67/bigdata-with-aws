output "mwaa_environment_name" {
  description = "Nome do ambiente MWAA."
  value       = aws_mwaa_environment.mwaa.name
}

output "mwaa_airflow_url" {
  description = "URL da UI do Airflow."
  value       = aws_mwaa_environment.mwaa.webserver_url
  sensitive   = true
}

output "mwaa_execution_role_arn" {
  description = "ARN da IAM Role de execução do MWAA."
  value       = aws_iam_role.mwaa_exec_role.arn
}
