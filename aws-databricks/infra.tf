###############################################################################
#
# Internet Gateway
#
###############################################################################

resource "aws_internet_gateway" "igw" {
  vpc_id = var.vpc_id
  tags = {
    Name = "${local.prefix}-databricks-igw"
  }
}

###############################################################################
#
# Nat Gateway
#
###############################################################################

resource "aws_eip" "nat" {
  # checkov:skip=CKV2_AWS_19: ADD REASON
  vpc = true
  tags = {
    Name = "${local.prefix}-databricks-nat"
  }
}

resource "aws_nat_gateway" "gateway" {
  allocation_id = element(
    try(aws_eip.nat[*].id, []),
    0
  )
  subnet_id = var.public_subnet_id

  tags = {
    Name = "${local.prefix}-databricks-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.gateway.id

  timeouts {
    create = "5m"
  }
}

###############################################################################
#
# Route tables
#
###############################################################################

resource "aws_route_table" "private" {
  vpc_id = var.vpc_id
  tags = {
    Name = "${local.prefix}-databricks-private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id
  tags = {
    Name = "${local.prefix}-databricks-public"
  }

}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = var.private_subnet_ids
  subnet_id      = each.value
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = var.public_subnet_id
  route_table_id = aws_route_table.public.id
}

###############################################################################
#
# Databricks security group
#
###############################################################################

resource "aws_security_group" "databricks_sg" {
  # checkov:skip=CKV2_AWS_5: ADD REASON
  name        = "${local.prefix}-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    self        = true
    description = "Allow all internal TCP and UDP"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }

  tags = {
    Name = "allow_tls"
  }
}

###############################################################################
#
# VPC Endpoints
#
###############################################################################

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "3.2.0"

  vpc_id             = var.vpc_id
  security_group_ids = [aws_security_group.databricks_sg.id]

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = [aws_route_table.private.id]
      tags = {
        Name = "${local.prefix}-s3-vpc-endpoint"
      }
    },
    sts = {
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = tolist(var.private_subnet_ids)
      tags = {
        Name = "${local.prefix}-sts-vpc-endpoint"
      }
    },
    kinesis-streams = {
      service             = "kinesis-streams"
      private_dns_enabled = true
      subnet_ids          = tolist(var.private_subnet_ids)
      tags = {
        Name = "${local.prefix}-kinesis-vpc-endpoint"
      }
    },
  }
}
