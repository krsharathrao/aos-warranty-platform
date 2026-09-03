import sys, json, boto3
from datetime import date
from decimal import Decimal
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DecimalType, DateType

args = getResolvedOptions(sys.argv, ["JDBC_URL", "DB_SECRET_ARN"])
secret = json.loads(boto3.client("secretsmanager").get_secret_value(SecretId=args["DB_SECRET_ARN"])["SecretString"])
props = {"user": secret["username"], "password": secret["password"], "driver": "org.postgresql.Driver"}
sc = SparkContext(); glueContext = GlueContext(sc); spark = glueContext.spark_session

customers_schema = StructType([StructField("customer_id", StringType(), False), StructField("customer_name", StringType()), StructField("region", StringType()), StructField("state", StringType())])
materials_schema = StructType([StructField("material_id", StringType(), False), StructField("material_description", StringType()), StructField("product_family", StringType()), StructField("warranty_years", IntegerType())])
sales_schema = StructType([StructField("order_id", StringType(), False), StructField("customer_id", StringType()), StructField("material_id", StringType()), StructField("sale_date", DateType()), StructField("sale_price", DecimalType(10,2))])
claims_schema = StructType([StructField("claim_id", StringType(), False), StructField("order_id", StringType()), StructField("claim_date", DateType()), StructField("claim_amount", DecimalType(10,2)), StructField("failure_code", StringType())])

customers = spark.createDataFrame([("C001","John Smith","North America","WI"),("C002","Alice Brown","North America","TX"),("C003","Robert Jones","North America","CA")], customers_schema)
materials = spark.createDataFrame([("M001","50 Gallon Electric Water Heater","Electric",6),("M002","40 Gallon Gas Water Heater","Gas",6),("M003","Hybrid Heat Pump Water Heater","Hybrid",10)], materials_schema)
sales = spark.createDataFrame([("SO001","C001","M001",date(2018,1,1),Decimal("899.00")),("SO002","C002","M002",date(2022,6,15),Decimal("1099.00")),("SO003","C003","M003",date(2020,3,12),Decimal("1699.00"))], sales_schema)
claims = spark.createDataFrame([("WC001","SO001",date(2025,2,10),Decimal("450.00"),"LEAK"),("WC002","SO002",date(2024,8,1),Decimal("350.00"),"VALVE"),("WC003","SO003",date(2025,1,15),Decimal("675.00"),"COMPRESSOR")], claims_schema)

for name, df in [("customers",customers),("materials",materials),("sales_orders",sales),("warranty_claims",claims)]:
    df.write.jdbc(url=args["JDBC_URL"], table=f"public.{name}", mode="overwrite", properties=props)
    print(f"Seeded public.{name}: {df.count()} rows")
print("SOURCE SEED COMPLETE")
