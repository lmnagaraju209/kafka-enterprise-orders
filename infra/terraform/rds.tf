########################################
# RDS SUBNET GROUP (USE EXISTING SUBNETS)
########################################

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = local.private_subnets

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

########################################
# RDS INSTANCE (PostgreSQL)
########################################

resource "aws_db_instance" "orders_db" {
  identifier              = "${var.project_name}-db"
  allocated_storage       = 20
  max_allocated_storage   = 50
  storage_type            = "gp3"

  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.micro"

  publicly_accessible     = false

  username                = var.rds_username
  password                = var.rds_password
  db_name                 = replace(var.project_name, "/[^a-zA-Z0-9]/", "")

  # Use existing RDS SG
  vpc_security_group_ids  = [data.aws_security_group.rds.id]

  # Use existing subnets
  db_subnet_group_name    = aws_db_subnet_group.main.name

  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0

  tags = {
    Name = "${var.project_name}-db"
  }
}
