provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

variable "lambda_function_name" {
  default = "lambda_start_function"
}

data "archive_file" "lambda_start_server_archive" {
  type        = "zip"
  source_file = "lambdas/start_server.py"
  output_path = "lambda_start_function_payload.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "policy_ec2_document" {
  statement {
    effect = "Allow"
    actions = ["ec2:Describe*", "ec2:StartInstances", "ec2:StopInstances"]
    resources = ["*"]
  }
  statement {
      effect = "Allow"
      actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:CreateLogDelivery", "logs:PutLogEvents"]
      resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "policy_ec2" {
  name        = "policy_ec2_for_lambda"
  description = "A test policy"
  policy      = data.aws_iam_policy_document.policy_ec2_document.json
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.policy_ec2.arn
}

resource "aws_lambda_function" "start_server_lambda" {

  filename      = "lambda_start_function_payload.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "start_server.lambda_handler"
  source_code_hash = data.archive_file.lambda_start_server_archive.output_base64sha256
  runtime = "python3.12"
  timeout = 120
  logging_config {
    log_format = "Text"
  }

  environment {
    variables = {
      stack = "conan"
    }
  }
}

resource "aws_lambda_function_url" "start_server_url" {
  function_name      = aws_lambda_function.start_server_lambda.function_name
  authorization_type = "NONE"
}