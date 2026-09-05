mock_provider "aws" {}

variables {
  github_repository = {
    owner         = "example-org"
    name          = "example-repo"
    owner_id      = "123456"
    repository_id = "789012"
  }
  github_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
}

run "reject_overbroad_vpc" {
  command = plan
  variables {
    vpc_cidr = "10.0.0.0/8"
  }
  expect_failures = [var.vpc_cidr]
}

run "reject_public_vpc" {
  command = plan
  variables {
    vpc_cidr = "8.8.0.0/20"
  }
  expect_failures = [var.vpc_cidr]
}

run "reject_noncanonical_vpc" {
  command = plan
  variables {
    vpc_cidr = "10.42.1.1/20"
  }
  expect_failures = [var.vpc_cidr]
}

run "reject_too_small_vpc" {
  command = plan
  variables {
    vpc_cidr = "10.42.0.0/25"
  }
  expect_failures = [var.vpc_cidr]
}

run "reject_duplicate_zones" {
  command = plan
  variables {
    availability_zones = ["us-east-1a", "us-east-1a"]
  }
  expect_failures = [var.availability_zones]
}

run "reject_wrong_region_zones" {
  command = plan
  variables {
    availability_zones = ["us-west-2a", "us-west-2b"]
  }
  expect_failures = [var.availability_zones]
}

run "reject_wildcard_repository" {
  command = plan
  variables {
    github_repository = {
      owner = "example-org"
      name  = "*"
    }
  }
  expect_failures = [var.github_repository]
}

run "reject_partial_immutable_ids" {
  command = plan
  variables {
    github_repository = {
      owner    = "example-org"
      name     = "example-repo"
      owner_id = "123456"
    }
  }
  expect_failures = [var.github_repository]
}

run "reject_environment_subject_injection" {
  command = plan
  variables {
    github_environment = "production:ref:refs/heads/*"
  }
  expect_failures = [var.github_environment]
}

run "reject_other_oidc_issuer" {
  command = plan
  variables {
    github_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/example.org"
  }
  expect_failures = [var.github_oidc_provider_arn]
}
