# Operator runbook

## Validate without AWS

Use Terraform 1.16.1 and run the README quickstart. Provider downloads require
network access to the official Terraform registry and release servers. The tests
substitute the AWS provider with `mock_provider "aws"` and use `command = plan`
for every run. They neither authenticate to AWS nor provision infrastructure.
No AWS CLI, account, secrets, or `terraform.tfvars` is needed for this path.

If the provider cannot start, check your Terraform platform with `terraform
version` and your machine architecture. Use a matching native Terraform build,
then initialize again. An x86 build under emulation can time out while starting
the large AWS provider on Apple Silicon.

## Prepare a manual sandbox deployment

This procedure is documentation, not evidence of a deployment. No real plan,
apply, STS exchange, or S3 request was performed while building this lab.

1. Obtain authorization for a dedicated AWS sandbox account and a named owner
   for its costs. Use short-lived administrator-approved credentials to bootstrap
   the foundation, with permissions for the resources in this root module. The
   publisher role created here cannot create VPCs, IAM roles, or buckets.
2. Confirm the AWS account ID and region. The provider's `allowed_account_ids`
   ties the expected account to the OIDC provider ARN. Check selected AZs exist
   and are available to this account. Check VPC CIDR overlap against existing
   VPCs, peering, VPN, and future networks; syntax checks do not detect overlap.
3. Have the account administrator provide the existing GitHub OIDC provider ARN
   with issuer `https://token.actions.githubusercontent.com` and client ID
   `sts.amazonaws.com`. The root module references, but does not create or own,
   this shared account identity provider. The administrator must verify its
   configuration separately.
4. Copy `terraform.tfvars.example` to `terraform.tfvars` and replace the synthetic
   values. For GitHub.com repositories created after July 15, 2026, or opted in
   to immutable subjects, supply the real owner ID and repository ID. Obtain them
   using `gh api repos/OWNER/REPO --jq '{owner_id: .owner.id, repository_id: .id}'`.
   Only omit both IDs after verifying that the repository uses classic subjects.
   Custom subject templates and GitHub Enterprise Server need a separate review.
5. Create the exact GitHub environment name in the target repository. Require
   review for deployments and restrict allowed branches/tags. A subject bound to
   an environment does **not** also bind a branch. A workflow from any permitted
   branch using that environment can request the token. Keep workflow changes
   under code review and protect the deployment branch.
6. Decide how to protect state before applying. This demo uses local state;
   do not commit or share it. For team use, configure a separately bootstrapped,
   encrypted, access-controlled remote backend with locking and a recovery plan.
   Do not put backend credentials in configuration or command arguments.
7. Rerun `terraform init -input=false` after any backend change, then run the
   following commands yourself after reviewing the account context:

   ```sh
   terraform plan -out=sandbox.tfplan
   terraform show sandbox.tfplan
   # Review every resource and action, then explicitly approve it:
   terraform apply sandbox.tfplan
   ```

   A first plan should create only this lab's VPC, subnets, route table and
   associations, security groups, S3 configuration and publisher role/policy.
   The default security group resource manages only the default group of the
   newly created VPC. Stop if the plan proposes changes to unrelated resources.
   Store the plan securely and remove it when no longer needed.

## Verify in AWS after an approved apply

Mocked tests cannot prove AWS IAM authorization, routing behavior, account policy
compatibility, resource availability, or deployment success. An operator should
independently verify those controls in the sandbox:

- Inspect actual route tables and subnet associations; ensure no internet route,
  NAT, transit gateway, peering or IPv6 route appeared. Inspect both groups for
  ingress and egress rules. AWS DNS resolver traffic has special security-group
  behavior; empty groups are not a universal DNS firewall.
- Inspect S3 public-access settings, object ownership, encryption and versioning.
  IAM Access Analyzer can help assess resource policies, but is not configured
  or invoked by this repository.
- Compare the actual token's **claims**, without publishing the token, to
  `expected_oidc_subject` and audience `sts.amazonaws.com`. Never paste a token
  into an issue or log. Validate trust from the allowed repository/environment;
  confirm wrong-repository and wrong-environment attempts fail.
- In a separately reviewed publishing workflow, use `permissions: { contents:
  read, id-token: write }`, the exact protected `environment`, and a vetted,
  SHA-pinned OIDC credentials action with audience `sts.amazonaws.com`. This
  repository includes only validation CI and does not install such a workflow.
- With the publisher session, test a synthetic single-object PUT under
  `releases/` with the explicit `AES256` server-side-encryption header. Confirm
  uploads outside that prefix, uploads without the header, object reads/deletes,
  and IAM operations are denied. A single `s3api put-object` fits this policy;
  multipart and sync workflows need their own reviewed permission model.

SSE-S3 uses S3-managed encryption keys. This does not implement customer-managed
KMS key isolation. The publisher can create new versions of existing keys under
its prefix; versioning is not immutable storage. Readers and application
consumers need separate policies. The bucket is reached through the public S3
service endpoint with IAM/TLS, and is not restricted to this VPC.

## Investigate drift or access failures

Run a fresh plan with your authorized sandbox credentials. Inspect any changed
OIDC subject format, renamed/transferred repository, environment controls, bucket
policy, role attachments, and organization SCPs before broadening permissions.
An account administrator could attach additional policies to the role; the
inline policy here is not a permissions boundary. Do not fix an access failure
by attaching an administrator policy or adding wildcard trust.

For network connectivity, this lab intentionally provides no internet egress,
S3 endpoint, application rules, compute or workload. Add connectivity only for a
reviewed application requirement with tests and a cost estimate. Production
adoption also needs logging/flow logs, monitoring, encryption-key decisions,
backup/retention policy and account-level preventive controls.

## Cleanup and costs

Terraform validation and mocked tests do not create AWS charges. A real deployment
and subsequent uploads can incur S3 storage, requests, transfer, and retained
version costs. This lab creates no NAT gateway, public IPv4 address, or compute
instance. Consult current [S3 pricing](https://aws.amazon.com/s3/pricing/) and
[AWS VPC pricing](https://aws.amazon.com/vpc/pricing/) for your region before use.
GitHub-hosted CI is also subject to the repository owner's Actions allowance.

To retire a manually deployed sandbox, first confirm its account, state and
resource ownership. Disable the repository's publishing workflow. Review a
`terraform plan -destroy` before making changes. The bucket has
`force_destroy = false`: an operator must explicitly review and remove retained
objects and versions before deletion. Review retention obligations first.
Do not run account-wide cleanup or destroy shared OIDC infrastructure. The
repository provides no automatic cleanup or cloud deployment script.
