resource "aws_glue_connection" "network" {
  name            = "aos-postgres-network"
  connection_type = "NETWORK"

  physical_connection_requirements {
    availability_zone      = aws_subnet.private_a.availability_zone
    security_group_id_list = [aws_security_group.glue.id]
    subnet_id              = aws_subnet.private_a.id
  }
}

locals {
  jdbc_url      = "jdbc:postgresql://${aws_db_instance.postgres.address}:5432/aosdb"
  db_secret_arn = aws_db_instance.postgres.master_user_secret[0].secret_arn
  script_base   = "s3://${aws_s3_bucket.data.bucket}/scripts"
}

resource "aws_glue_job" "seed" {
  name              = "aos-seed-postgres"
  role_arn          = aws_iam_role.glue.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  timeout           = 20
  connections       = [aws_glue_connection.network.name]

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "${local.script_base}/seed_source.py"
  }

  default_arguments = {
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
    "--JDBC_URL"                         = local.jdbc_url
    "--DB_SECRET_ARN"                    = local.db_secret_arn
  }

  depends_on = [
    aws_iam_role_policy.glue_access,
    aws_vpc_endpoint.interface,
    aws_vpc_endpoint.s3
  ]
}

resource "aws_glue_job" "ingest" {
  name              = "aos-ingest-raw"
  role_arn          = aws_iam_role.glue.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  timeout           = 20
  connections       = [aws_glue_connection.network.name]

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "${local.script_base}/ingest_raw.py"
  }

  default_arguments = {
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
    "--JDBC_URL"                         = local.jdbc_url
    "--DB_SECRET_ARN"                    = local.db_secret_arn
    "--DATA_BUCKET"                      = aws_s3_bucket.data.bucket
  }

  depends_on = [
    aws_iam_role_policy.glue_access,
    aws_vpc_endpoint.interface,
    aws_vpc_endpoint.s3
  ]
}

resource "aws_glue_job" "silver" {
  name              = "aos-transform-warranty-silver"
  role_arn          = aws_iam_role.glue.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  timeout           = 20
  connections       = [aws_glue_connection.network.name]

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "${local.script_base}/transform_silver.py"
  }

  default_arguments = {
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
    "--DATA_BUCKET"                      = aws_s3_bucket.data.bucket
  }

  depends_on = [
    aws_iam_role_policy.glue_access,
    aws_vpc_endpoint.s3
  ]
}
