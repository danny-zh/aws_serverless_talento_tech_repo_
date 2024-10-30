variable "environment" {
  type        = string
  description = "Environment for the deployment"
  default     = "dev"
}

variable "main_resources_name" {
  type        = string
  description = "Main resources across the deployment"
  default     = "flask-lambda"
}

variable "lambda_function_name_dynamo" {
  type        = string
  description = "Name for lambda function to work with dynamodb resource"
  default     = "Crud-DynamoDB-Function"
}

variable "lambda_python_runtime" {
  type        = string
  description = "Default version for python in lambda"
  default     = "python3.12"
}


variable "aws_resource_tags" {
  type        = map(string)
  description = "Tags to be applied to each resource this TF configuration creates."
  default = {
    project     = "flask-app"
    version     = "1.2"
    environment = "dev"
    owner       = "dz@dzcol.com"
  }
}

variable "email_source" {
  type        = string
  description = "Source for email sending"
  default = "user@example.com"
  sensitive = true
}

