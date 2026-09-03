data "archive_file" "aiops" {
  type        = "zip"
  source_file = "${path.module}/../aiops/lambda_function.py"
  output_path = "${path.module}/aiops.zip"
}

resource "aws_iam_role" "aiops" {
  name = "aos-aiops-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "aiops" {
  name = "AOSAIOpsPolicy"
  role = aws_iam_role.aiops.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["glue:GetJobRun"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "aiops" {
  function_name    = "aos-aiops-rca"
  role             = aws_iam_role.aiops.arn
  runtime          = "python3.13"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.aiops.output_path
  source_code_hash = data.archive_file.aiops.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      BEDROCK_MODEL_ID = var.bedrock_model_id
      AWS_REGION_NAME  = var.aws_region
    }
  }
}

resource "aws_cloudwatch_log_group" "aiops" {
  name              = "/aws/lambda/${aws_lambda_function.aiops.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_event_rule" "glue_failure" {
  name = "aos-glue-failure"

  event_pattern = jsonencode({
    source      = ["aws.glue"]
    detail-type = ["Glue Job State Change"]
    detail = {
      jobName = [
        aws_glue_job.seed.name,
        aws_glue_job.ingest.name,
        aws_glue_job.silver.name
      ]
      state = ["FAILED", "TIMEOUT", "STOPPED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "aiops" {
  rule      = aws_cloudwatch_event_rule.glue_failure.name
  target_id = "AIOpsRCA"
  arn       = aws_lambda_function.aiops.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aiops.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.glue_failure.arn
}
