locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags
}

module "glue" {
  source = "./modules/glue"

  project_name      = var.project_name
  environment       = var.environment
  aws_region        = var.aws_region
  scripts_bucket_id = module.s3.scripts_bucket_id
  raw_bucket_arn    = module.s3.raw_bucket_arn
  processed_bucket_arn = module.s3.processed_bucket_arn
  common_tags       = local.common_tags
}

module "mwaa" {
  source = "./modules/mwaa"

  project_name    = var.project_name
  environment     = var.environment
  aws_region      = var.aws_region
  dags_bucket_id  = module.s3.dags_bucket_id
  airflow_version = var.mwaa_airflow_version
  glue_job_arn    = module.glue.glue_job_arn
  common_tags     = local.common_tags
}
