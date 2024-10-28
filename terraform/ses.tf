# Create ses email bases identity
resource "aws_ses_email_identity" "ses_send_email" {
  email = var.email_source
}

# Create iam policy document
data "aws_iam_policy_document" "ses_send_email" {
  statement {
    actions   = ["SES:SendEmail", "SES:SendRawEmail"]
    resources = [aws_ses_email_identity.ses_send_email.arn]

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
  }
}

# Attach the policy to the entity resource
# After succesfull creation you need to manually approve your email
resource "aws_ses_identity_policy" "ses_send_email" {
  name = lower("ses-email-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}-${random_string.id.result}")

  identity = aws_ses_email_identity.ses_send_email.arn
  policy   = data.aws_iam_policy_document.ses_send_email.json
 
}
