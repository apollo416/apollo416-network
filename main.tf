
locals {
  vpc_name = "vpc-${var.env}"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = local.vpc_name
    Env  = var.env
    Rev  = var.rev
  }
}

resource "aws_default_network_acl" "main" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    to_port    = 0
    from_port  = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    to_port    = 0
    from_port  = 0
  }

  tags = {
    Name = "${local.vpc_name}-default-nacl"
    Env  = var.env
    Rev  = var.rev
    Look = local.vpc_name
  }
}

resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.vpc_name}-default-sg"
    Env  = var.env
    Rev  = var.rev
    Look = local.vpc_name
  }
}

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  tags = {
    Name = "${local.vpc_name}-default-rt"
    Env  = var.env
    Rev  = var.rev
    Look = local.vpc_name
  }
}

resource "aws_subnet" "private_subnet" {
  count             = length(var.vpc_private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_private_subnets[count.index]
  availability_zone = var.vpc_azs[count.index]
  tags = {
    Name = "${local.vpc_name}-private-${count.index}"
    Env  = var.env
    Rev  = var.rev
    Look = local.vpc_name
  }
}

resource "aws_subnet" "public_subnet" {
  count             = length(var.vpc_public_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_public_subnets[count.index]
  availability_zone = var.vpc_azs[count.index]
  tags = {
    Name = "${local.vpc_name}-public-${count.index}"
    Env  = var.env
    Rev  = var.rev
    Look = local.vpc_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.vpc_name}-gw"
    Env  = var.env
    Rev  = var.rev
    Look = local.vpc_name
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${local.vpc_name}-gateway-rt"
    Env  = var.env
    Rev  = var.rev
    Look = "${local.vpc_name}-gw"
  }
}

resource "aws_route_table_association" "main" {
  count          = length(var.vpc_public_subnets)
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "main" {
  depends_on = [aws_internet_gateway.main]
  domain     = "vpc"
  tags = {
    Name = "${local.vpc_name}-nat-gw-eip"
    Env  = var.env
    Rev  = var.rev
    Look = "${local.vpc_name}-nat-gw"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public_subnet[0].id
  tags = {
    Name = "${local.vpc_name}-nat-gw"
    Env  = var.env
    Rev  = var.rev
    Look = "${local.vpc_name}-gw"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = {
    Name = "${local.vpc_name}-nat-rt"
    Env  = var.env
    Rev  = var.rev
    Look = "${local.vpc_name}-nat-gw"
  }
}

resource "aws_route_table_association" "private_route_assoc" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.main.arn
  log_destination = aws_cloudwatch_log_group.main.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  tags = {
    Name = "${local.vpc_name}-flow-log"
    Env  = var.env
    Rev  = var.rev
    Look = local.vpc_name
  }
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "${local.vpc_name}-logs"
  retention_in_days = 365
  kms_key_id        = data.terraform_remote_state.account.outputs.kms_key_arn
  tags = {
    Name = "${local.vpc_name}-vpc-logs"
    Env  = var.env
    Rev  = var.rev
    Look = "${local.vpc_name}-flow-log"
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "main" {
  name               = "${local.vpc_name}-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = {
    Name = "${local.vpc_name}-flow-log-role"
    Env  = var.env
    Rev  = var.rev
    Look = "${local.vpc_name}-flow-log"
  }
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:*",
      "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:${local.vpc_name}-logs:*"
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_flow_log.main.arn]
    }
  }
}

resource "aws_iam_role_policy" "main" {
  name   = "${local.vpc_name}-flow-log-policy"
  role   = aws_iam_role.main.id
  policy = data.aws_iam_policy_document.policy.json
}
