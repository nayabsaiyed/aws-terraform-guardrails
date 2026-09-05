# Primary references

Checked September 5, 2026. These describe upstream behavior; they do not prove
that this example was deployed or tested against AWS.

- [Terraform provider mocking](https://developer.hashicorp.com/terraform/language/tests/mocking): mocked provider behavior and its limits.
- [Terraform releases](https://releases.hashicorp.com/terraform/1.16.1/): Terraform 1.16.1 archives and checksums.
- [AWS provider 6.63.0](https://registry.terraform.io/providers/hashicorp/aws/6.63.0/docs): pinned provider release used for validation.
- [GitHub AWS OIDC setup](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws): audience, subject, and environment restrictions.
- [GitHub OIDC reference](https://docs.github.com/en/actions/reference/security/oidc): immutable subject IDs, classic subjects, and environment precedence.
- [S3 policy condition keys](https://docs.aws.amazon.com/AmazonS3/latest/userguide/amazon-s3-policy-keys.html): prefix, transport, and encryption conditions.
- [S3 IAM integration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security_iam_service-with-iam.html): bucket and object resource permissions.
- [Pinned checkout action](https://github.com/actions/checkout/commit/fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09): official `v5` tag resolved using GitHub's API.
- [Pinned setup-terraform action](https://github.com/hashicorp/setup-terraform/commit/b9cd54a3c349d3f38e8881555d616ced269862dd): official `v3` tag resolved using GitHub's API.
