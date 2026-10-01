output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "distribution_id" {
  value = aws_cloudfront_distribution.site.id
}

output "url" {
  value = "https://${coalesce(var.domain_name, aws_cloudfront_distribution.site.domain_name)}"
}
