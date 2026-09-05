# This is an artifact-publishing deployment role, not a Terraform execution role.
resource "aws_iam_role" "publisher" {
  name_prefix          = "${var.name}-publisher-"
  description          = "Publish release artifacts from one GitHub repository and protected environment"
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = var.github_oidc_provider_arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = local.oidc_subject
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "publisher" {
  name = "publish-release-artifacts"
  role = aws_iam_role.publisher.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ListReleasePrefix"
        Effect    = "Allow"
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.artifacts.arn
        Condition = { StringLike = { "s3:prefix" = "releases/*" } }
      },
      {
        Sid      = "PublishEncryptedReleaseObjects"
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.artifacts.arn}/releases/*"
        Condition = {
          StringEquals = { "s3:x-amz-server-side-encryption" = "AES256" }
        }
      }
    ]
  })
}
