# Defile policy document, it will be used for the lambda role 
data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

#Create lambda role for frontend lambda
resource "aws_iam_role" "lambda_role" {
  name               = lower("iam-role-lambda-front-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}-${random_string.id.result}")
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
}

# Create iam policy for lambda invokation
resource "aws_iam_policy" "lambda_invoke_policy" {
  name = lower("lambda_invoke_policy-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}-${random_string.id.result}")
  description = "test policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "lambda:InvokeFunction",
            "Resource": [aws_lambda_function.insertarDatoslambda.arn, aws_lambda_function.lambda_email_ses.arn]
        }
    ]
})
}

# # Add "AWSLambdaBasicExecutionRole" to the role for the Lambda Function
resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Add lambda invoke to the role for the Lambda Function
resource "aws_iam_role_policy_attachment" "lambda_invoke_lambda" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_invoke_policy.arn
}


# Create ZIP file for the source code at deployment time
data "archive_file" "lambda_source_package" {
  type        = "zip"
  source_dir  = "${local.src_root_path}/src"
  output_path = "${local.src_root_path}/src.zip"
}

# Lambda Layer Install (Python dependencies)
resource "null_resource" "lambda_layer_install_deps" {
  provisioner "local-exec" {
    command     = "make install"
    working_dir = local.root_path
  }

  # Enforce to always execute the command
  triggers = {
    always_run = "${timestamp()}"
  }
}

# Create ZIP file for Lambda Layer (Python dependencies)
data "archive_file" "lambda_layer_package" {
  type        = "zip"
  source_dir  = "${local.lambda_layers_root_path}/modules"
  output_path = "${local.lambda_layers_root_path}/modules/lambda_layer_package.zip"

  depends_on = [null_resource.lambda_layer_install_deps]
}

# Define Lambda Layer to package the require dependencies
resource "aws_lambda_layer_version" "lambda_layer" {
  filename                 = "${local.lambda_layers_root_path}/modules/lambda_layer_package.zip"
  layer_name               = "${var.main_resources_name}-layer"
  compatible_runtimes      = ["python3.12"]
  compatible_architectures = ["x86_64"]
  source_code_hash         = data.archive_file.lambda_layer_package.output_base64sha256 # Enforce re-deploy on changes

  depends_on = [data.archive_file.lambda_layer_package]

}

# Create lambda function to process main.py
resource "aws_lambda_function" "lambda" {
  function_name    = lower("lambda-front-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}-${random_string.id.result}")
  filename         = "${local.src_root_path}/src.zip"
  handler          = "main.handler"
  role             = aws_iam_role.lambda_role.arn
  runtime          = var.lambda_python_runtime
  timeout          = 20
  architectures    = ["x86_64"]
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  source_code_hash = data.archive_file.lambda_source_package.output_base64sha256 # Enforce re-deploy on changes


  environment {
    variables = {
      ENVIRONMENT = var.environment
      S3_ARN = "https://${aws_s3_bucket.static_content.id}.s3.amazonaws.com"
      CDN_ARN = "https://${aws_cloudfront_distribution.cdn.domain_name}"
      API_GW= split("://",aws_apigatewayv2_api.api_gateway.api_endpoint)[1]
      BACKEND_FUNCTION_NAME = aws_lambda_function.insertarDatoslambda.function_name
      EMAIL_FUNCTION_NAME = aws_lambda_function.lambda_email_ses.function_name
    }
  }

  depends_on = [
    data.archive_file.lambda_source_package,
    data.archive_file.lambda_layer_package,
    aws_apigatewayv2_api.api_gateway,
    aws_cloudfront_distribution.cdn
  ]

}

# Provide a url to test the lambda function (just for testing, leave commented)
# resource "aws_lambda_function_url" "lambda_url" {
#   function_name      = aws_lambda_function.lambda.function_name
#   authorization_type = "NONE"
# }

