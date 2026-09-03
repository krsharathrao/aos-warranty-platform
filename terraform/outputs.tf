output "data_bucket_name" {
  value = aws_s3_bucket.data.bucket
}

output "rds_identifier" {
  value = aws_db_instance.postgres.identifier
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "rds_secret_arn" {
  value     = aws_db_instance.postgres.master_user_secret[0].secret_arn
  sensitive = true
}

output "seed_job_name" {
  value = aws_glue_job.seed.name
}

output "ingest_job_name" {
  value = aws_glue_job.ingest.name
}

output "silver_job_name" {
  value = aws_glue_job.silver.name
}

output "raw_crawler_name" {
  value = aws_glue_crawler.raw.name
}

output "silver_crawler_name" {
  value = aws_glue_crawler.silver.name
}

output "athena_results_s3" {
  value = "s3://${aws_s3_bucket.data.bucket}/athena-results/"
}

output "glue_security_group_id" {
  value = aws_security_group.glue.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}
