########################################
# RDS SUBNET GROUP
########################################

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

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
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.micro"
  publicly_accessible     = true

  username                = var.rds_username
  password                = var.rds_password
  db_name                 = var.project_name

  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name

  skip_final_snapshot     = true

  tags = {
    Name = "${var.project_name}-db"
  }
}
