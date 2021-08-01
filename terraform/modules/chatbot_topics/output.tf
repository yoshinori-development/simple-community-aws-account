output "notification-topic" {
  value = aws_sns_topic.notification
}

output "kms_key" {
  value = aws_kms_key.topic_encription
}
