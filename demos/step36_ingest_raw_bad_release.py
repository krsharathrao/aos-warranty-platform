import sys, json, boto3
from datetime import date
from decimal import Decimal
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext

args = getResolvedOptions(sys.argv, ["JDBC_URL", "DB_SECRET_ARN", "DATA_BUCKET"])
secret = json.loads(boto3.client("secretsmanager").get_secret_value(SecretId=args["DB_SECRET_ARN"])["SecretString"])
props = {"user": secret["username"], "password": secret["password"], "driver": "org.postgresql.Driver"}
sc = SparkContext(); glueContext = GlueContext(sc); spark = glueContext.spark_session
for table in ["customers","materials","sales_orders","warranty_claims"]:
    df = spark.read.jdbc(url=args["JDBC_URL"], table=f"public.{table}", properties=props)

    # STEP 36 DEMO ONLY: inject one orphan warranty claim.
    if table == "warranty_claims":
        bad_claim = spark.createDataFrame(
            [(
                "WC999",
                "SO_DOES_NOT_EXIST",
                date(2025, 1, 1),
                Decimal("500.00"),
                "DEMO_BAD_DATA"
            )],
            schema=df.schema
        )
        df = df.unionByName(bad_claim)
        print("DEMO: Injected orphan warranty claim WC999")
    print(f"public.{table}: {df.count()} rows")
    target = f"s3://{args['DATA_BUCKET']}/raw/{table}/"
    df.write.mode("overwrite").parquet(target)
    print(f"Written {target}")
print("RAW INGEST COMPLETE")
