output "id" {
  description = "An identifier that changes, when changes to this resource occur."
  value       = aws_s3_object.talos_wipe_state.etag
}
