output "kms_key" {
  value = aws_kms_key.parameter_encription
}

output "session_manager_policy" {
  value = aws_iam_policy.session-manager
}