output "bucket" {
  value = aws_s3_bucket.logging
}

output "kms_key" {
  value = aws_kms_key.logging
}
