###############################################################################
#
# Internet Gateway
#
###############################################################################

resource "aws_internet_gateway" "igw" {
  count  = var.igw_id != null ? 0 : 1
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.prefix}-databricks-igw"
  }
}

###############################################################################
#
# Nat Gateway
#
###############################################################################

resource "aws_eip" "nat" {
  # checkov:skip=CKV2_AWS_19: Instances are created by databricks, thus there are no instances to attach to
  vpc = true
  tags = {
    Name = "${var.prefix}-databricks-nat"
  }
}

resource "aws_nat_gateway" "gateway" {
  allocation_id = element(
    try(aws_eip.nat[*].id, []),
    0
  )
  subnet_id = var.public_subnet_id

  tags = {
    Name = "${var.prefix}-databricks-nat"
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
    Name = "${var.prefix}-databricks-private"
  }
}

resource "aws_route_table" "public" {
  count  = var.igw_id != null ? 0 : 1
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.prefix}-databricks-public"
  }

}

resource "aws_route" "public_internet_gateway" {
  count                  = var.igw_id != null ? 0 : 1
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id != null ? var.igw_id : aws_internet_gateway.igw[0].id

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
  count          = var.igw_id != null ? 0 : 1
  subnet_id      = var.public_subnet_id
  route_table_id = aws_route_table.public[0].id
}

###############################################################################
#
# Databricks security group
#
###############################################################################

resource "aws_security_group" "databricks_sg" {
  # checkov:skip=CKV2_AWS_5: Instances are created by databricks, thus there are no instances to attach to
  name        = "${var.prefix}-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    self        = true
    description = "Allow all internal TCP and UDP"
    from_port   = 0
    to_port     = 0
    # allows all protocols
    protocol = "-1"
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # databricks requires any source
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    # databricks requires any source
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }

  egress {
    from_port = 443
    protocol  = "TCP"
    to_port   = 443
    # databricks requires any source
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    # databricks requires any source
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow TLS outbound traffic"
  }

  egress {
    from_port = 3306
    protocol  = "TCP"
    to_port   = 3306
    # databricks requires any source
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    # databricks requires any source
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow MySQL outbound traffic"
  }

  #Private link (opt)
  #  egress {
  #    from_port = 6666
  #    protocol  = "TCP"
  #    to_port   = 6666
  #    cidr_blocks = ["0.0.0.0/0"]
  #    ipv6_cidr_blocks = ["::/0"]
  #    description = "Allow SSH outbound traffic"
  #  }

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
        Name = "${var.prefix}-s3-vpc-endpoint"
      }
    },
    sts = {
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = tolist(var.private_subnet_ids)
      tags = {
        Name = "${var.prefix}-sts-vpc-endpoint"
      }
    },
    kinesis-streams = {
      service             = "kinesis-streams"
      private_dns_enabled = true
      subnet_ids          = tolist(var.private_subnet_ids)
      tags = {
        Name = "${var.prefix}-kinesis-vpc-endpoint"
      }
    },
  }
}
