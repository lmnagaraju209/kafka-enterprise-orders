########################################
# RDS SUBNET GROUP (PRIVATE SUBNETS)
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
  engine_version          = "15"   # ✅ FIXED: let AWS choose latest supported 15.x

  instance_class          = "db.t3.micro"

  publicly_accessible     = false

  username                = var.rds_username
  password                = replace(var.rds_password, "/[[:cntrl:]]/", "")
  db_name                 = replace(var.project_name, "/[^a-zA-Z0-9]/", "")

  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name

  skip_final_snapshot     = true
  deletion_protection     = false

  backup_retention_period = 0

  tags = {
    Name = "${var.project_name}-db"
  }
}
