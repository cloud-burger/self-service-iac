module "process_order_payment" {
  source             = "../../modules/lambda"
  name               = "${var.project}-process-order-payment"
  lambda_role        = aws_iam_role.lambda_role.arn
  handler            = "src/api/handlers/process-order-payment.handler"
  source_bucket      = module.global_variables.source_bucket
  source_key         = "process-order-payment.zip"
  project            = var.project
  subnet_ids         = local.aws_private_subnets
  security_group_ids = [aws_security_group.lambda_process_order_payment.id]
  source_code_hash   = base64encode(sha256("${var.commit_hash}"))

  environment_variables = {
    DATABASE_USERNAME           = resource.aws_ssm_parameter.database_username.value
    DATABASE_NAME               = resource.aws_ssm_parameter.database_name.value
    DATABASE_PASSWORD           = resource.aws_ssm_parameter.database_password.value
    DATABASE_PORT               = resource.aws_ssm_parameter.database_port.value
    DATABASE_HOST               = resource.aws_ssm_parameter.database_host.value
    DATABASE_CONNECTION_TIMEOUT = 120000
  }
}

resource "aws_lambda_event_source_mapping" "process_order_payment_event_source_mapping" {
  event_source_arn = aws_sqs_queue.process_order_payment_queue.arn
  enabled          = true
  function_name    = module.process_order_payment.arn
  batch_size       = 10
}
