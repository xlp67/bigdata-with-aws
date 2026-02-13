from __future__ import annotations
import pendulum
from airflow.models.dag import DAG
from airflow.providers.amazon.aws.operators.glue import GlueJobOperator
from datetime import timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='glue_orchestration_dag',
    default_args=default_args,
    description='DAG para orquestrar um job do AWS Glue para processamento de dados.',
    schedule_interval='@daily',
    start_date=pendulum.datetime(2024, 1, 1, tz="UTC"),
    catchup=False,
    tags=['glue', 'data-pipeline'],
) as dag:
    glue_job_name = "bigdata-process-data-{{ var.value.get('environment', 'dev') }}"

    trigger_glue_job = GlueJobOperator(
        task_id='trigger_process_data_job',
        job_name=glue_job_name,
        wait_for_completion=True,
        verbose=True,
    )
