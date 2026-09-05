mock_provider "aws" {
  override_during = plan
  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::synthetic-guardrails-artifacts"
    }
  }
}

variables {
  github_repository = {
    owner         = "example-org"
    name          = "example-repo"
    owner_id      = "123456"
    repository_id = "789012"
  }
  github_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
}

run "isolated_network_defaults" {
  command = plan
  assert {
    condition = (
      length(aws_subnet.isolated) == 2 &&
      aws_subnet.isolated[0].cidr_block == "10.42.0.0/22" &&
      aws_subnet.isolated[1].cidr_block == "10.42.4.0/22" &&
      alltrue([for subnet in aws_subnet.isolated : !subnet.map_public_ip_on_launch])
    )
    error_message = "The subnets must be distinct derived ranges with no public IP allocation."
  }
  assert {
    condition     = length(aws_route_table.isolated.route) == 0
    error_message = "The subnet route table must have no configured routes beyond AWS's local route."
  }
  assert {
    condition = (
      length(aws_security_group.workload.ingress) == 0 &&
      length(aws_security_group.workload.egress) == 0 &&
      length(aws_default_security_group.locked.ingress) == 0 &&
      length(aws_default_security_group.locked.egress) == 0
    )
    error_message = "Both workload and VPC default security groups must have no ingress or egress rules."
  }
}

run "artifact_storage_controls" {
  command = plan
  assert {
    condition = (
      aws_s3_bucket_public_access_block.artifacts.block_public_acls &&
      aws_s3_bucket_public_access_block.artifacts.block_public_policy &&
      aws_s3_bucket_public_access_block.artifacts.ignore_public_acls &&
      aws_s3_bucket_public_access_block.artifacts.restrict_public_buckets
    )
    error_message = "All four S3 public access protections must be enabled."
  }
  assert {
    condition = (
      one(aws_s3_bucket_server_side_encryption_configuration.artifacts.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256" &&
      aws_s3_bucket_versioning.artifacts.versioning_configuration[0].status == "Enabled" &&
      aws_s3_bucket_ownership_controls.artifacts.rule[0].object_ownership == "BucketOwnerEnforced" &&
      !aws_s3_bucket.artifacts.force_destroy
    )
    error_message = "Artifacts need encryption, version history, disabled ACLs, and explicit cleanup."
  }
  assert {
    condition = (
      jsondecode(aws_s3_bucket_policy.artifacts.policy).Statement[0].Effect == "Deny" &&
      jsondecode(aws_s3_bucket_policy.artifacts.policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false" &&
      contains(jsondecode(aws_s3_bucket_policy.artifacts.policy).Statement[0].Resource, "arn:aws:s3:::synthetic-guardrails-artifacts/*")
    )
    error_message = "The bucket policy must explicitly deny non-TLS object requests."
  }
}

run "immutable_repository_environment_trust" {
  command = plan
  assert {
    condition = (
      length(jsondecode(aws_iam_role.publisher.assume_role_policy).Statement) == 1 &&
      jsondecode(aws_iam_role.publisher.assume_role_policy).Statement[0].Effect == "Allow" &&
      jsondecode(aws_iam_role.publisher.assume_role_policy).Statement[0].Action == "sts:AssumeRoleWithWebIdentity" &&
      jsondecode(aws_iam_role.publisher.assume_role_policy).Statement[0].Principal.Federated == var.github_oidc_provider_arn &&
      jsondecode(aws_iam_role.publisher.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com" &&
      jsondecode(aws_iam_role.publisher.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == "repo:example-org@123456/example-repo@789012:environment:production" &&
      !can(jsondecode(aws_iam_role.publisher.assume_role_policy).Statement[0].Condition.StringLike) &&
      aws_iam_role.publisher.max_session_duration == 3600
    )
    error_message = "Trust must match one immutable repository, one environment, and the STS audience exactly."
  }
}

run "classic_repository_trust" {
  command = plan
  variables {
    github_repository = {
      owner = "legacy-org"
      name  = "legacy-repo"
    }
    github_environment = "release"
  }
  assert {
    condition     = jsondecode(aws_iam_role.publisher.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == "repo:legacy-org/legacy-repo:environment:release"
    error_message = "Classic subjects must still match one repository and environment exactly."
  }
}

run "publisher_permissions_are_prefix_scoped" {
  command = plan
  assert {
    condition = (
      length(jsondecode(aws_iam_role_policy.publisher.policy).Statement) == 2 &&
      jsondecode(aws_iam_role_policy.publisher.policy).Statement[0].Action == "s3:ListBucket" &&
      jsondecode(aws_iam_role_policy.publisher.policy).Statement[0].Resource == "arn:aws:s3:::synthetic-guardrails-artifacts" &&
      jsondecode(aws_iam_role_policy.publisher.policy).Statement[0].Condition.StringLike["s3:prefix"] == "releases/*" &&
      jsondecode(aws_iam_role_policy.publisher.policy).Statement[1].Action == "s3:PutObject" &&
      jsondecode(aws_iam_role_policy.publisher.policy).Statement[1].Resource == "arn:aws:s3:::synthetic-guardrails-artifacts/releases/*" &&
      jsondecode(aws_iam_role_policy.publisher.policy).Statement[1].Condition.StringEquals["s3:x-amz-server-side-encryption"] == "AES256"
    )
    error_message = "The publisher may only list its prefix and put explicitly encrypted objects under that prefix."
  }
}

run "smallest_vpc_boundary" {
  command = plan
  variables {
    vpc_cidr = "192.168.8.0/24"
  }
  assert {
    condition     = aws_subnet.isolated[1].cidr_block == "192.168.8.64/26"
    error_message = "A /24 VPC must yield valid distinct /26 subnets."
  }
}

run "largest_vpc_boundary" {
  command = plan
  variables {
    vpc_cidr = "172.31.0.0/16"
  }
  assert {
    condition     = aws_subnet.isolated[1].cidr_block == "172.31.64.0/18"
    error_message = "A /16 VPC must yield valid distinct /18 subnets."
  }
}
