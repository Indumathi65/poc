resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = { Name = "mig-vpc" }
}

resource "aws_subnet" "private" {
  for_each = toset(var.private_subnet_cidrs)
  vpc_id   = aws_vpc.this.id
  cidr_block = each.value
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = { Name = "mig-subnet-${each.key}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group" "dms_sg" {
  name   = "dms-sg"
  vpc_id = aws_vpc.this.id
  description = "Allow DMS to talk to Cloud SQL and allow Aurora access"

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [var.gcp_vpc_cidr]
    description = "Postgres from GCP"
  }

  egress {
    from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB subnet group
resource "aws_db_subnet_group" "mig" {
  name       = "mig-db-subnet-group"
  subnet_ids = values(aws_subnet.private)[*].id
  tags = { Name = "mig-db-subnet-group" }
}

# Aurora cluster
resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "aurora-mig-cluster"
  engine             = "aurora-postgresql"
  engine_version     = "14.10"
  master_username    = var.aurora_username
  master_password    = var.aurora_password
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.mig.name
  vpc_security_group_ids = [aws_security_group.dms_sg.id]
}

resource "aws_rds_cluster_instance" "instance" {
  count              = 1
  identifier         = "aurora-mig-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.r5.large"
}

# Secrets Manager for credentials
resource "aws_secretsmanager_secret" "cloudsql_secret" { name = "cloudsql-source-creds" }
resource "aws_secretsmanager_secret_version" "cloudsql_secret_ver" {
  secret_id     = aws_secretsmanager_secret.cloudsql_secret.id
  secret_string = jsonencode({ username = var.cloudsql_user, password = var.cloudsql_password })
}

resource "aws_secretsmanager_secret" "aurora_secret" { name = "aurora-target-creds" }
resource "aws_secretsmanager_secret_version" "aurora_secret_ver" {
  secret_id     = aws_secretsmanager_secret.aurora_secret.id
  secret_string = jsonencode({ username = var.aurora_username, password = var.aurora_password })
}

# DMS Subnet Group
resource "aws_dms_replication_subnet_group" "dms_subnet" {
  replication_subnet_group_id = "dms-subnet-group"
  subnet_ids = values(aws_subnet.private)[*].id
}

# DMS replication instance
resource "aws_dms_replication_instance" "rep" {
  replication_instance_id = "dms-repl-instance-1"
  replication_instance_class = "dms.r6.large"
  allocated_storage = 100
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms_subnet.replication_subnet_group_id
  vpc_security_group_ids = [aws_security_group.dms_sg.id]
}

# DMS source endpoint (Cloud SQL private IP)
resource "aws_dms_endpoint" "source" {
  endpoint_id = "cloudsql-source-endpoint"
  endpoint_type = "source"
  engine_name = "postgres"
  username = var.cloudsql_user
  password = var.cloudsql_password
  server_name = var.cloudsql_private_ip
  port = 5432
  database_name = var.cloudsql_dbname
}

# DMS target endpoint (Aurora)
resource "aws_dms_endpoint" "target" {
  endpoint_id = "aurora-target-endpoint"
  endpoint_type = "target"
  engine_name = "postgres"
  username = var.aurora_username
  password = var.aurora_password
  server_name = aws_rds_cluster.aurora.endpoint
  port = 5432
  database_name = var.aurora_dbname
}

# DMS replication task
resource "aws_dms_replication_task" "task" {
  replication_task_id = "dms-task-cloudsql-to-aurora"
  migration_type = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.rep.replication_instance_arn
  source_endpoint_arn = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn = aws_dms_endpoint.target.endpoint_arn
  table_mappings = <<JSON
{
  "rules": [{
    "rule-type":"selection","rule-id":"1","rule-name":"1",
    "object-locator": {"schema-name":"%","table-name":"%"},"rule-action":"include"
  }]
}
JSON
  replication_task_settings = <<JSON
{"TargetMetadata":{"SupportLobs":true}}
JSON
  depends_on = [aws_dms_replication_instance.rep]
}