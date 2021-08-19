output "bucket" {
  value = aws_s3_bucket.logging
}

output "prefix_alb" {
  value = local.prefix_alb
}