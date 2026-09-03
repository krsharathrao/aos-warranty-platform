import sys, json, boto3
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext

args = getResolvedOptions(sys.argv, ["JDBC_URL", "DB_SECRET_ARN", "DATA_BUCKET"])
secret = json.loads(boto3.client("secretsmanager").get_secret_value(SecretId=args["DB_SECRET_ARN"])["SecretString"])
props = {"user": secret["username"], "password": secret["password"], "driver": "org.postgresql.Driver"}
sc = SparkContext(); glueContext = GlueContext(sc); spark = glueContext.spark_session
for table in ["customers","materials","sales_orders","warranty_claims"]:
    df = spark.read.jdbc(url=args["JDBC_URL"], table=f"public.{table}", properties=props)
    print(f"public.{table}: {df.count()} rows")
    target = f"s3://{args['DATA_BUCKET']}/raw/{table}/"
    df.write.mode("overwrite").parquet(target)
    print(f"Written {target}")
print("RAW INGEST COMPLETE")
