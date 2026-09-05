# Local verification evidence

Recorded September 5, 2026, using Terraform **1.16.1**, official
`hashicorp/aws` provider **6.63.0**, and macOS ARM64.

The native Terraform archive was downloaded from the official HashiCorp release
server and matched its published SHA256 checksum:

```text
terraform_1.16.1_darwin_arm64.zip
e22cba761ddbd4d218939b28715ab3af37aaf8a42efa41f7d75b2c3d73636060
```

Terraform initialization reported the provider as **signed by HashiCorp**.
The lock file is included in the repository. The Terraform archive checksum
was compared over HTTPS; a separate GPG verification of the CLI archive's
checksum signature was not performed.

| Check | Result |
|---|---|
| `terraform fmt -check -recursive` | Exit 0 |
| `terraform init -backend=false -input=false -lockfile=readonly` | Exit 0 |
| `terraform validate -no-color` | Exit 0, configuration valid |
| `terraform test -no-color` | Exit 0, 17 passed, 0 failed |

See [full final output](verification.txt) and [test output](terraform-test.txt).
All test runs use a mocked AWS provider and `command = plan`. Synthetic account
and repository IDs are used. No AWS credentials were supplied, and no real
AWS plan, apply, API request, OIDC exchange, or cloud resource was created.

The input rejection tests were written before adding variable validation.
The initial native run failed with `Missing expected failure` for the overbroad
VPC input, as recorded in [the red test](red-input-validation-native.txt).
Terraform stops the remaining runs in that test file after the first failure;
that evidence is not a claim that every rejection was observed failing first.
The final suite covers ten rejected configurations and seven valid configuration
scenarios, with multiple assertions in the network, storage, and IAM scenarios.

An initial x86 Terraform/provider run under emulation timed out starting the AWS
provider. Repeating validation with the verified native ARM64 build succeeded.
The native test results above are the verification evidence.

## What these results do not establish

- AWS-side IAM enforcement, STS authentication or S3 upload outcomes.
- Real network routing, DNS filtering, application connectivity or availability.
- Account policies, quotas, region/AZ availability, CIDR overlap with live networks,
  or the configuration of the existing OIDC provider.
- Compliance, penetration-test results, production readiness or customer outcomes.
- A remote GitHub Actions run. The checked-in workflow is ready for publication;
  its run history becomes separate evidence after the repository is published.

Mocked tests validate expressions and intended provider resource configuration.
The [operator runbook](../docs/runbook.md) describes the independent live checks
needed after any separately approved sandbox deployment.
