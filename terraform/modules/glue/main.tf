data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_role" {
  name               = "${var.project_name}-glue-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
  tags               = var.common_tags
}

data "aws_iam_policy_document" "glue_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${var.raw_bucket_arn}/*",
      "${var.processed_bucket_arn}/*",
      "arn:aws:s3:::${var.scripts_bucket_id}/*"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [
      var.raw_bucket_arn,
      var.processed_bucket_arn,
      "arn:aws:s3:::${var.scripts_bucket_id}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "glue_policy" {
  name   = "${var.project_name}-glue-policy-${var.environment}"
  role   = aws_iam_role.glue_role.id
  policy = data.aws_iam_policy_document.glue_policy.json
}

resource "aws_iam_role_policy_attachment" "glue_service_policy" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_glue_job" "process_data" {
  name         = "${var.project_name}-process-data-${var.environment}"
  role_arn     = aws_iam_role.glue_role.arn
  glue_version = "4.0"
  worker_type  = "G.1X"
  number_of_workers = 5

  command {
    name            = "glueetl"
    script_location = "s3://${var.scripts_bucket_id}/src/glue/jobs/process_data.py"
    python_version  = "3"
  }

  default_arguments = {
    # Argumentos padrão do Glue
    "--TempDir"                            = "s3://${var.scripts_bucket_id}/temporary/"
    "--enable-metrics"                     = ""
    "--enable-continuous-cloudwatch-log"   = "true"
    "--job-bookmark-option"                = "job-bookmark-disable"
    
    # Otimizações de performance e resiliência
    "--spark-sql-adaptive-enabled"         = "true"
    "--spark-sql-adaptive-coalescePartitions-enabled" = "true"
    "--spark-sql-adaptive-skewJoin-enabled" = "true"

    # Argumentos customizados para o script
    "--input_path"                         = "${var.raw_bucket_arn}/input_data/"
    "--output_path"                        = "${var.processed_bucket_arn}/output_data/"
  }

  tags = var.common_tags
}
