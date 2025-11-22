############################################
# RDS SUBNET GROUP
############################################
resource "aws_db_subnet_group" "orders" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "${var.project_name}-db-subnets"
  }
}

############################################
# RDS SECURITY GROUP
############################################
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow Postgres from ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

############################################
# RDS INSTANCE (POSTGRES)
############################################
resource "aws_db_instance" "orders_db" {
  identifier             = "${var.project_name}-db"
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_type           = "gp3"

  engine                 = "postgres"
  engine_version         = "16"                # FIXED VERSION
  instance_class         = "db.t3.micro"

  db_subnet_group_name   = aws_db_subnet_group.orders.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  db_name                = "ordersdb"
  username               = "orders_user"
  password               = var.rds_password   # from secrets

  skip_final_snapshot    = true

  publicly_accessible    = true               # EDU use only

  tags = {
    Name = "${var.project_name}-db"
  }
}
