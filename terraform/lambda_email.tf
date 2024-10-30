#Create role for lambda email
resource "aws_iam_role" "lambda_email_ses_role" {
  name               = lower("iam-role-lambda-email-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}-${random_string.id.result}")
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
}

# Create iam policy for lambda email to call SES
resource "aws_iam_policy" "lambda_email_ses_policy" {
  name = lower("lambda_email_policy-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}-${random_string.id.result}")
  description = "test policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail",
                "ses:SendRawEmail",
                "ses:ListIdentities",
                "ses:VerifyEmailIdentity"
            ],
            "Resource": "*"
        }
    ]
})
}

# Attach policy for lambda logs to cloudwatch
resource "aws_iam_role_policy_attachment" "lambda_email_execution_role" {
  role       = aws_iam_role.lambda_email_ses_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach policy for lambda email role
resource "aws_iam_role_policy_attachment" "lambda_email_ses" {
  role       = aws_iam_role.lambda_email_ses_role.name
  policy_arn = aws_iam_policy.lambda_email_ses_policy.arn
}

# Create ZIP file for the source code at deployment time
data "archive_file" "email_lambda_source_package" {
  type        = "zip"
  source_dir  = "${local.src_root_path}/email"
  output_path = "${local.src_root_path}/email.zip"
}

# Lambda for email handling
resource "aws_lambda_function" "lambda_email_ses" {
  function_name = lower("lambda-email-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}-${random_string.id.result}")
  filename      = "${local.src_root_path}/email.zip"
  role          = aws_iam_role.lambda_email_ses_role.arn
  handler       = "main.handler"
  runtime       = var.lambda_python_runtime                  
  source_code_hash = data.archive_file.email_lambda_source_package.output_base64sha256

  environment {
    variables = {
      email_source = var.email_source
    }
  }

  depends_on = [
    data.archive_file.email_lambda_source_package,
  ]
  tags = var.aws_resource_tags
}




