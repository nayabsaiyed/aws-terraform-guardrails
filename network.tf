resource "aws_vpc" "foundation" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}

resource "aws_subnet" "isolated" {
  count                   = 2
  vpc_id                  = aws_vpc.foundation.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 2, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-isolated-${count.index + 1}" }
}

# No internet gateway, NAT gateway, peering, or endpoint is created.
# AWS automatically supplies the VPC-local route.
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.foundation.id
  route  = []
  tags   = { Name = "${var.name}-isolated" }
}

resource "aws_route_table_association" "isolated" {
  count          = 2
  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated.id
}

# Scope is the default group of THIS new VPC, never an existing/default VPC.
resource "aws_default_security_group" "locked" {
  vpc_id  = aws_vpc.foundation.id
  ingress = []
  egress  = []
  tags    = { Name = "${var.name}-default-deny" }
}

resource "aws_security_group" "workload" {
  name_prefix = "${var.name}-workload-"
  description = "No traffic permitted until application-specific rules are reviewed"
  vpc_id      = aws_vpc.foundation.id
  ingress     = []
  egress      = []
  tags        = { Name = "${var.name}-workload" }
}
