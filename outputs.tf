output "vpc_id" {
  description = "ID of the new isolated VPC."
  value       = aws_vpc.foundation.id
}
output "subnet_ids" {
  description = "IDs of the two isolated subnets."
  value       = aws_subnet.isolated[*].id
}
output "workload_security_group_id" {
  description = "Empty security group for application-specific rules."
  value       = aws_security_group.workload.id
}
output "artifact_bucket_name" {
  description = "Private artifact bucket; permitted publishing keys begin releases/."
  value       = aws_s3_bucket.artifacts.id
}
output "publisher_role_arn" {
  description = "Role for an independently reviewed publishing workflow. It cannot apply this root module."
  value       = aws_iam_role.publisher.arn
}
output "expected_oidc_subject" {
  description = "Exact sub expected from the selected repository's protected environment."
  value       = local.oidc_subject
}
