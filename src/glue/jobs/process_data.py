import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.conf import SparkConf
from pyspark.sql.functions import col, year, current_date

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'input_path', 'output_path'])

conf = SparkConf()
conf.set("spark.sql.adaptive.enabled", "true")
conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")
conf.set("spark.sql.adaptive.skewJoin.enabled", "true")
conf.set("spark.sql.shuffle.partitions", "200")
conf.set("spark.sql.autoBroadcastJoinThreshold", "100m")
conf.set("spark.executor.memoryOverhead", "1024")

sc = SparkContext(conf=conf)
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

input_path = args['input_path']
output_path = args['output_path']

try:
    source_dyf = glueContext.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={"paths": [input_path]},
        format="json",
        transformation_ctx="source_dyf"
    )
    source_df = source_dyf.toDF()

except Exception as e:
    print(f"Diretório de entrada {input_path} vazio ou não encontrado. Criando DataFrame de exemplo.")
    data = [
        (1, "Fulano", 30, "Engenheiro"),
        (2, "Ciclana", 25, "Analista"),
        (3, "Beltrano", 35, "Gerente")
    ]
    columns = ["id", "nome", "idade", "cargo"]
    source_df = spark.createDataFrame(data, columns)

if source_df.count() > 0:
    transformed_df = source_df.withColumn("ano_nascimento_aprox", (year(current_date()) - col("idade")))

    transformed_dyf = DynamicFrame.fromDF(transformed_df, glueContext, "transformed_dyf")

    glueContext.write_dynamic_frame.from_options(
        frame=transformed_dyf,
        connection_type="s3",
        connection_options={"path": output_path},
        format="parquet",
        transformation_ctx="sink_parquet"
    )

job.commit()
