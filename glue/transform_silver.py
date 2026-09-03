import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from pyspark.sql.functions import col, add_months, when
args = getResolvedOptions(sys.argv, ["DATA_BUCKET"])
sc = SparkContext(); glueContext = GlueContext(sc); spark = glueContext.spark_session
bucket = args["DATA_BUCKET"]; raw = f"s3://{bucket}/raw"; silver = f"s3://{bucket}/silver/warranty/"
c = spark.read.parquet(f"{raw}/customers/").alias("c")
m = spark.read.parquet(f"{raw}/materials/").alias("m")
s = spark.read.parquet(f"{raw}/sales_orders/").alias("s")
w = spark.read.parquet(f"{raw}/warranty_claims/").alias("w")
joined = w.join(s,col("w.order_id")==col("s.order_id"),"left").join(c,col("s.customer_id")==col("c.customer_id"),"left").join(m,col("s.material_id")==col("m.material_id"),"left")
silver_df = joined.select(col("w.claim_id"),col("w.order_id"),col("s.customer_id"),col("c.customer_name"),col("c.region"),col("c.state"),col("s.material_id"),col("m.material_description"),col("m.product_family"),col("s.sale_date"),col("s.sale_price"),col("w.claim_date"),col("w.claim_amount"),col("w.failure_code"),col("m.warranty_years"))
silver_df = silver_df.withColumn("warranty_expiry_date", add_months(col("sale_date"), col("warranty_years")*12))
silver_df = silver_df.withColumn("warranty_status", when(col("claim_date")<=col("warranty_expiry_date"),"VALID").otherwise("OUT_OF_WARRANTY"))
silver_df.show(20, truncate=False)
silver_df.write.mode("overwrite").parquet(silver)
print("SILVER TRANSFORM COMPLETE")
