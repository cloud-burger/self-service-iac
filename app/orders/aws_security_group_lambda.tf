resource "aws_security_group" "lambda_process_order_payment" {
  name   = "lambda_process_order_payment"
  vpc_id = local.aws_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "lambda_to_rds" {
  type                     = "ingress"
  from_port                = 5432 # Porta do banco de dados na instância RDS
  to_port                  = 5432 # Porta do banco de dados na instância RDS
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_public_sg.id                # ID da security group da RDS
  source_security_group_id = aws_security_group.lambda_process_order_payment.id # ID da security group da Lambda
}
