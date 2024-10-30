
# Configurar el bucket para servir una página web estática
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.static_content.bucket

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "static_files_test_cdn" {
  bucket = aws_s3_bucket.static_content.bucket
  key    = "index.html"                     # S3 key, the file path in S3
  source = "index.html"  # The local file to upload
}

# Política del bucket para permitir acceso solo a través de CloudFront
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.static_content.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          "Service": "cloudfront.amazonaws.com"
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.static_content.arn}/static*",
        Condition = {
          StringEquals = {
            "AWS:Referer": aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

# Crear la distribución de CloudFront para servir el contenido del bucket de S3
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.static_content.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.static_content.id
  }

  enabled = true

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.static_content.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  # Añadir el bloque de restricciones (sin restricciones geográficas)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Usar el certificado predeterminado de CloudFront
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Optimización de costos: distribución limitada a regiones populares
  price_class = "PriceClass_200"

  # Establecer el objeto raíz predeterminado
  default_root_object = "index.html"

  tags = var.aws_resource_tags
}




