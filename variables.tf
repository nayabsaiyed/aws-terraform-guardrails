variable "vpc_cidr" {
  description = "Canonical RFC1918 IPv4 VPC CIDR, /16 through /24. Subnets are derived with two extra bits."
  type        = string
  default     = "10.42.0.0/20"
  validation {
    condition = try(
      can(cidrnetmask(var.vpc_cidr)) &&
      tonumber(split("/", var.vpc_cidr)[1]) >= 16 &&
      tonumber(split("/", var.vpc_cidr)[1]) <= 24 &&
      cidrhost(var.vpc_cidr, 0) == split("/", var.vpc_cidr)[0] &&
      can(regex("^(10\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.|192\\.168\\.)", cidrhost(var.vpc_cidr, 0))),
    false)
    error_message = "Use a canonical private IPv4 network between /16 and /24, such as 10.42.0.0/20."
  }
}

variable "region" {
  description = "Commercial AWS region for this lab. GovCloud and China partitions are outside this example's scope."
  type        = string
  default     = "us-east-1"
  validation {
    condition     = can(regex("^(us|eu|ap|sa|ca|me|af|il|mx)-[a-z]+-[0-9]+$", var.region))
    error_message = "Supply a commercial AWS region such as us-east-1."
  }
}

variable "name" {
  description = "Short unique lab name used in resource names and tags."
  type        = string
  default     = "guardrails-lab"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,23}$", var.name))
    error_message = "Use 3 to 24 lowercase letters, digits, or hyphens, starting with a letter."
  }
}

variable "availability_zones" {
  description = "Exactly two distinct standard availability-zone names in the selected region; verify account availability before apply."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  validation {
    condition = (
      length(var.availability_zones) == 2 &&
      length(toset(var.availability_zones)) == 2 &&
      alltrue([for zone in var.availability_zones : can(regex("^${var.region}[a-z]$", zone))])
    )
    error_message = "Provide two different standard availability zones in var.region."
  }
}

variable "github_repository" {
  description = "Exact repository identity. Set both immutable IDs for newer/opted-in repositories; omit both only for classic subjects."
  type = object({
    owner         = string
    name          = string
    owner_id      = optional(string)
    repository_id = optional(string)
  })
  validation {
    condition = (
      can(regex("^[A-Za-z0-9][A-Za-z0-9-]{0,38}$", var.github_repository.owner)) &&
      can(regex("^[A-Za-z0-9_.-]{1,100}$", var.github_repository.name)) &&
      (
        (var.github_repository.owner_id == null && var.github_repository.repository_id == null) ||
        (can(regex("^[1-9][0-9]*$", var.github_repository.owner_id)) && can(regex("^[1-9][0-9]*$", var.github_repository.repository_id)))
      )
    )
    error_message = "Use an exact owner/repository without wildcards; immutable subjects require both numeric IDs."
  }
}

variable "github_environment" {
  description = "One protected GitHub environment. This focused example permits letters, digits, underscores and hyphens only."
  type        = string
  default     = "production"
  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,64}$", var.github_environment))
    error_message = "Use one literal environment name (1-64 letters, digits, underscores or hyphens)."
  }
}

variable "github_oidc_provider_arn" {
  description = "An existing GitHub OIDC provider in the target AWS account, configured for sts.amazonaws.com. This lab does not create shared identity infrastructure."
  type        = string
  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:oidc-provider/token\\.actions\\.githubusercontent\\.com$", var.github_oidc_provider_arn))
    error_message = "Use a commercial AWS IAM OIDC provider ARN for token.actions.githubusercontent.com."
  }
}
