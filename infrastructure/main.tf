provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "random_pet" "lambda_bucket_name" {
  prefix = "testofcode"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_sqs_queue" "message_queue" {
  name = "testofcode-iac-queue"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../bin/funky"
  output_path = "../bin/funky.zip"
}

resource "aws_lambda_function" "funky" {
  function_name = "testofcode-iac-func"
  filename      = data.archive_file.lambda_zip.output_path
  runtime       = "go1.x"
  handler       = "funky"
  role          = aws_iam_role.lambda_role.arn # Roles testofcode-iac-lambda-role
  source_code_hash = filebase64sha256(
    data.archive_file.lambda_zip.output_path
  )
  memory_size = 128
  timeout     = 10
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.lambda_bucket.id # Bucket Name : testofcode...
    }
  }
}

resource "aws_lambda_event_source_mapping" "funky" {
  event_source_arn = aws_sqs_queue.message_queue.arn
  function_name    = aws_lambda_function.funky.arn
  batch_size       = 1
}

# add Roles testofcode-iac-lambda-role
resource "aws_iam_role" "lambda_role" {
  name = "testofcode-iac-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    }
  }]
}
EOF
}

# add Policy lambda-s3-policy
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-s3-policy"
  description = "IAM policy for Lambda to access S3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "${aws_s3_bucket.lambda_bucket.arn}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "${aws_sqs_queue.message_queue.arn}"
    }
  ]
}
EOF
}

resource "aws_s3_bucket_policy" "lambda_bucket_policy" {
  bucket = aws_s3_bucket.lambda_bucket.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.lambda_role.name}"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.lambda_bucket.arn}/*"
      ]
    }
  ]
}
EOF
}

# add AWSLambdaBasicExecutionRole to Roles(testofcode-iac-lambda-role) -> Permissions policies
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# add lambda-s3-policy to Roles(testofcode-iac-lambda-role) -> Permissions policies
resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
