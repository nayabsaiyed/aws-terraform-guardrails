# Design and implementation sequence

This lab demonstrates two independently useful controls in one small AWS account
foundation: isolated networking and a narrow CI publishing identity. It is
original demonstration code, not a production landing zone.

The root module owns only resources it creates: a VPC, two derived subnets,
security groups, and an artifact bucket plus publisher role. It references an
existing account OIDC provider to avoid duplicating shared identity infrastructure.
The publisher role can upload to `releases/` in the new bucket. It cannot provision
this Terraform configuration. Network isolation does not restrict GitHub-hosted
runners; the bucket remains accessible through the public S3 service endpoint
with IAM authorization and TLS.

Implementation sequence:

1. Write expected-failure input tests and observe rejection missing before adding
   validation. Keep the raw result in `evidence/red-input-validation.txt`.
2. Implement bounded private IPv4 allocation, two distinct availability zones,
   empty security groups, and an explicit local-only subnet route table.
3. Write and implement assertions for S3 public access, encryption, versioning,
   exact OIDC audience/subject, and prefix-scoped write permissions.
4. Add an example variable file, operator runbook, and validation-only CI with
   pinned upstream actions. Never place deployment credentials in this repository.
5. Run formatting, provider schema validation, and mocked plan tests. Record
   exact tool versions and limitations in `evidence/README.md`.

Other approaches considered: a complete multi-account landing zone would obscure
reviewable controls; an IAM-only snippet would omit the networking and artifact
storage constraints. This root module keeps those concerns in separate `.tf`
files while remaining runnable with four Terraform commands.
