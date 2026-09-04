data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "aos-lab-vpc"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_a_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "aos-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_b_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "aos-private-b"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "aos-private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "glue" {
  # checkov:skip=CKV2_AWS_5:Glue SG is attached through aws_glue_connection; Glue creates service-managed ENIs dynamically at job runtime.

  name        = "aos-glue-sg"
  description = "Security group for AWS Glue Spark workers and Glue-managed ENIs"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow intra-Glue Spark worker communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow Glue workers to reach RDS, VPC endpoints and AWS services"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name        = "aos-rds-sg"
  description = "Security group for private PostgreSQL access from AWS Glue"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow PostgreSQL TCP 5432 from AWS Glue only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.glue.id]
  }

  egress {
    description = "Allow outbound responses from the PostgreSQL instance"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpce" {
  name        = "aos-vpce-sg"
  description = "Security group for private AWS interface VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTPS TCP 443 from AWS Glue to interface endpoints"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.glue.id]
  }

  egress {
    description = "Allow interface endpoint response traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  interface_services = toset(["sts", "secretsmanager", "glue"])
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_services

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id]
  security_group_ids  = [aws_security_group.vpce.id]

  tags = {
    Name = "aos-${each.value}-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "aos-s3-endpoint"
  }
}
