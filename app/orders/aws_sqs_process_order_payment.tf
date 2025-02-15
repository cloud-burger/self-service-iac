resource "aws_sqs_queue" "process_order_payment_queue_dlq" {
  content_based_deduplication       = false
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  name                              = "${var.project}-process-order-payment-queue-dlq"
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 30
}

resource "aws_sqs_queue" "process_order_payment_queue" {
  content_based_deduplication       = false
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  name                              = "${var.project}-process-order-payment-queue"
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 30
  redrive_policy = jsonencode(
    {
      deadLetterTargetArn = aws_sqs_queue.process_order_payment_queue_dlq.arn
      maxReceiveCount     = 5
    }
  )
}
