resource "aws_glue_catalog_database" "raw" {
  name = "aos_warranty_raw"
}

resource "aws_glue_catalog_database" "silver" {
  name = "aos_warranty_silver"
}

resource "aws_glue_catalog_database" "gold" {
  name = "aos_warranty_gold"
}

resource "aws_glue_crawler" "raw" {
  name          = "aos-raw-crawler"
  role          = aws_iam_role.glue.arn
  database_name = aws_glue_catalog_database.raw.name

  s3_target {
    path = "s3://${aws_s3_bucket.data.bucket}/raw/"
  }

  depends_on = [aws_iam_role_policy.glue_access]
}

resource "aws_glue_crawler" "silver" {
  name          = "aos-silver-crawler"
  role          = aws_iam_role.glue.arn
  database_name = aws_glue_catalog_database.silver.name

  s3_target {
    path = "s3://${aws_s3_bucket.data.bucket}/silver/warranty/"
  }

  depends_on = [aws_iam_role_policy.glue_access]
}
