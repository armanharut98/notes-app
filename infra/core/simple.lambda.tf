resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "${local.core_name_prefix}-lambda-bucket"
  tags = {
    Name = "${local.core_name_prefix}-lambda-bucket"
  }
}

data "aws_s3_bucket_object" "lambda_object" {
  bucket = aws_s3_bucket.lambda_bucket.bucket
  key    = "lambdas/simple_lambda"
}

resource "aws_security_group" "lambda_sg" {
  name = "simple-lambda-sg"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "simple-lambda-sg"
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "name" {
  role       = aws_iam_role.lambda_exec
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "simple_lambda" {
  function_name    = "simple_lambda"
  s3_bucket        = aws_s3_bucket.lambda_bucket
  s3_key           = "lambdas/simple_lambda"
  role             = aws_iam_role.lambda_exec.name
  runtime          = "nodejs16.x"
  handler          = "index.handler"
  source_code_hash = data.aws_s3_bucket_object.lambda_object.etag
}
