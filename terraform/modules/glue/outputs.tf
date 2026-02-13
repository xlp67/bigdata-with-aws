output "glue_job_name" {
  description = "Nome do Job do AWS Glue."
  value       = aws_glue_job.process_data.name
}

output "glue_job_arn" {
  description = "ARN do Job do AWS Glue."
  value       = aws_glue_job.process_data.arn
}

output "glue_role_arn" {
  description = "ARN da IAM Role do Glue."
  value       = aws_iam_role.glue_role.arn
}
