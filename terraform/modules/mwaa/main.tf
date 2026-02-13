resource "aws_vpc" "mwaa_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.common_tags, { Name = "${var.project_name}-mwaa-vpc-${var.environment}" })
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = merge(var.common_tags, { Name = "${var.project_name}-mwaa-private-subnet-${count.index}-${var.environment}" })
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.mwaa_vpc.id
  tags   = merge(var.common_tags, { Name = "${var.project_name}-mwaa-igw-${var.environment}" })
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.1${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags              = merge(var.common_tags, { Name = "${var.project_name}-mwaa-public-subnet-${count.index}-${var.environment}" })
}

resource "aws_eip" "nat" {
  count      = 2
  domain = "vpc"
  tags       = merge(var.common_tags, { Name = "${var.project_name}-mwaa-eip-nat-${count.index}-${var.environment}" })
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(var.common_tags, { Name = "${var.project_name}-mwaa-nat-gw-${count.index}-${var.environment}" })
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.mwaa_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = merge(var.common_tags, { Name = "${var.project_name}-mwaa-private-rt-${count.index}-${var.environment}" })
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "mwaa_sg" {
  name        = "${var.project_name}-mwaa-sg-${var.environment}"
  description = "Permite todo o tráfego interno na VPC para o MWAA"
  vpc_id      = aws_vpc.mwaa_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.mwaa_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

data "aws_iam_policy_document" "mwaa_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["airflow.amazonaws.com", "airflow-env.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mwaa_exec_role" {
  name               = "${var.project_name}-mwaa-exec-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.mwaa_assume_role.json
  tags               = var.common_tags
}

data "aws_iam_policy_document" "mwaa_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.dags_bucket_id}",
      "arn:aws:s3:::${var.dags_bucket_id}/*"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketPolicy"]
    resources = ["arn:aws:s3:::${var.dags_bucket_id}"]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:StartJobRun",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:BatchStopJobRun"
    ]
    resources = [var.glue_job_arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:GetLogRecord"
    ]
    resources = ["arn:aws:logs:${var.aws_region}:*:log-group:airflow-${aws_mwaa_environment.mwaa.name}-*"]
  }
  statement {
    effect  = "Allow"
    actions = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage"
    ]
    resources = ["arn:aws:sqs:${var.aws_region}:*:airflow-celery-*"]
  }
}

resource "aws_iam_policy" "mwaa_policy" {
  name   = "${var.project_name}-mwaa-policy-${var.environment}"
  policy = data.aws_iam_policy_document.mwaa_policy.json
}

resource "aws_iam_role_policy_attachment" "mwaa_policy_attach" {
  role       = aws_iam_role.mwaa_exec_role.name
  policy_arn = aws_iam_policy.mwaa_policy.arn
}

resource "aws_mwaa_environment" "mwaa" {
  name             = "${var.project_name}-mwaa-${var.environment}"
  airflow_version  = var.airflow_version
  execution_role_arn = aws_iam_role.mwaa_exec_role.arn
  source_bucket_arn  = "arn:aws:s3:::${var.dags_bucket_id}"
  dag_s3_path      = "src/dags"
  environment_class = "mw1.small"

  network_configuration {
    security_group_ids = [aws_security_group.mwaa_sg.id]
    subnet_ids         = aws_subnet.private[*].id
  }

  webserver_access_mode = "PUBLIC_ONLY"

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }
    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }
    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }
    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
    task_logs {
      enabled   = true
      log_level = "INFO"
    }
  }

  tags = var.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.mwaa_policy_attach,
    aws_route_table_association.private
  ]
}
