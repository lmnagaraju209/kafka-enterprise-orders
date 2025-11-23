# RDS INSTANCE ONLY — subnet group already exists

resource "aws_db_instance" "orders_db" {
  identifier             = "${var.project_name}-db"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20

  # Use existing imported name
  db_subnet_group_name = "kafka-enterprise-orders-db-subnets"

  username            = var.rds_username
  password            = var.rds_password
  publicly_accessible = false
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = {
    Name = "${var.project_name}-db"
  }
}

