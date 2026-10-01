output "media_bucket_name" {
  value = aws_s3_bucket.media.bucket
}

output "results_queue_url" {
  value = aws_sqs_queue.results.url
}

output "dlq_url" {
  value = aws_sqs_queue.lambda_dlq.url
}

output "lambda_function_name" {
  value = aws_lambda_function.moderation.function_name
}
