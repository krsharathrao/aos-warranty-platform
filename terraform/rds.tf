resource "aws_db_subnet_group" "main" {
  name = "aos-rds-subnet-group"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
}

resource "aws_db_instance" "postgres" {
  identifier = "aos-sap-simulator"

  engine         = "postgres"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "aosdb"
  username = "postgres"

  manage_master_user_password = true

  iam_database_authentication_enabled = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = false
  deletion_protection = false
  skip_final_snapshot = true
  apply_immediately   = true

  backup_retention_period    = 1
  auto_minor_version_upgrade = true

  copy_tags_to_snapshot = true

  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]
}
