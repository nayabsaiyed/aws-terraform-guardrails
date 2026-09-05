# Linux CI lockfile correction — September 5, 2026

The first real `Terraform guardrails` run on GitHub's Linux runner
[failed at validate](https://github.com/nayabsaiyed/aws-terraform-guardrails/actions/runs/33968830808)
for commit `0b79a17d0f8d9b37f86b4bad27444ca70cb83bb3`.
This was not a passing Terraform workflow; unrelated Dependabot jobs are not
validation evidence.

`terraform init -lockfile=readonly` downloaded AWS provider 6.63.0 and reported
it signed by HashiCorp, but warned that provider lock information was not saved.
The next `terraform validate` failed because the unpacked Linux provider did not
match a recorded content checksum. The lockfile contained archive checksums
(`zh`) and content checksums (`h1`) from macOS, but lacked the Linux amd64 `h1`.

The correction was generated, not hand-entered:

```sh
terraform providers lock -platform=linux_amd64
```

Terraform retrieved the official **signed by HashiCorp** Linux package and added
one content checksum while preserving the version and all existing checksums:

```text
h1:9cre7jh1lSs/9igpgAcENMUAUlYW3HCtkav3up4oit0=
```

CI retains `-lockfile=readonly` and all formatting, schema validation, and mocked
tests. No verification is bypassed, no provider version is changed, and no AWS
account is used. Local ARM64 checks pass after the correction; a fresh hosted
Terraform run on the corrected main commit is the remaining verification gate.

For a provider update, generate and review supported-platform checksums before
committing:

```sh
terraform providers lock \
  -platform=linux_amd64 \
  -platform=darwin_arm64 \
  -platform=darwin_amd64
```

See HashiCorp's [lockfile checksum documentation](https://developer.hashicorp.com/terraform/language/files/dependency-lock)
and [platform locking command](https://developer.hashicorp.com/terraform/cli/commands/providers/lock).
