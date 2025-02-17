resource "aws_cloudwatch_log_group" "process_order_payment_log_group" {
  name              = "/aws/lambda/${module.process_order_payment.function_name}"
  retention_in_days = 5
}
