output "bootstrap_bucket_name" {
  description = "S3 bucket name for bootstrap state"
  value       = aws_s3_bucket.bootstrap_state.bucket
}
