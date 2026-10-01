# --- Upload bucket (private) ---

resource "aws_s3_bucket" "media" {
  bucket_prefix = "${var.name}-media-"
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket                  = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Queues ---

resource "aws_sqs_queue" "results" {
  name                      = "${var.name}-moderation-results"
  message_retention_seconds = 345600
  sqs_managed_sse_enabled   = true
  tags                      = var.tags
}

resource "aws_sqs_queue" "lambda_dlq" {
  name                      = "${var.name}-moderation-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
  tags                      = var.tags
}

# --- Lambda ---

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/handler.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}-moderation"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-moderation"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
  tags               = var.tags
}

# Least privilege: read this bucket, call one Rekognition API, write two queues,
# write its own log group. Nothing else.
data "aws_iam_policy_document" "lambda" {
  statement {
    sid       = "ReadUploads"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.media.arn}/*"]
  }

  statement {
    sid       = "Moderate"
    actions   = ["rekognition:DetectModerationLabels"]
    resources = ["*"] # Rekognition image APIs do not support resource-level permissions.
  }

  statement {
    sid       = "PublishResults"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.results.arn, aws_sqs_queue.lambda_dlq.arn]
  }

  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "moderation"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_lambda_function" "moderation" {
  function_name    = "${var.name}-moderation"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.13"
  handler          = "handler.handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      RESULTS_QUEUE_URL = aws_sqs_queue.results.url
      MIN_CONFIDENCE    = tostring(var.min_confidence)
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy.lambda]
  tags       = var.tags
}

# --- S3 event -> Lambda ---

resource "aws_lambda_permission" "s3" {
  statement_id   = "AllowS3Invoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.moderation.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.media.arn
  source_account = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_notification" "media" {
  bucket = aws_s3_bucket.media.id

  dynamic "lambda_function" {
    for_each = toset([".jpg", ".jpeg", ".png"])
    content {
      lambda_function_arn = aws_lambda_function.moderation.arn
      events              = ["s3:ObjectCreated:*"]
      filter_suffix       = lambda_function.value
    }
  }

  depends_on = [aws_lambda_permission.s3]
}
