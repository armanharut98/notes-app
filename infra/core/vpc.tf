resource "aws_vpc" "core" {
  cidr_block = local.core_vpc_cidr
  tags = {
    Name = "${local.core_name_prefix}-vpc"
  }
}

resource "aws_subnet" "core_public" {
  count             = local.core_az_count
  vpc_id            = aws_vpc.core.id
  cidr_block        = cidrsubnet(aws_vpc.core.cidr_block, 8, count.index)
  availability_zone = "${local.core_region}${local.az_suffix[count.index]}"
  tags = {
    Name = "${terraform.workspace}-subnet-private-${local.az_suffix[count.index]}"
  }
}

resource "aws_subnet" "core_private" {
  count             = local.core_az_count
  vpc_id            = aws_vpc.core.id
  cidr_block        = cidrsubnet(aws_vpc.core.cidr_block, 8, 10 + count.index)
  availability_zone = "${local.core_region}${local.az_suffix[count.index]}"
  tags = {
    Name = "${terraform.workspace}-subnet-public-${local.az_suffix[count.index]}"
  }
}

resource "aws_internet_gateway" "core_ig" {
  vpc_id = aws_vpc.core.id
  tags = {
    Name = "${terraform.workspace}-internet-gateway"
  }
}

resource "aws_eip" "nat" {
  count  = local.core_az_count
  domain = "vpc"
  tags = {
    Name = "${terraform.workspace}-nat-eip-${local.az_suffix[count.index]}"
  }
}

resource "aws_nat_gateway" "core" {
  count         = local.core_az_count
  subnet_id     = aws_subnet.core_public[count.index].id
  allocation_id = aws_eip.nat[count.index].id
  tags = {
    Name = "${terraform.workspace}-nat-gateway-${local.az_suffix[count.index]}"
  }
}

resource "aws_route_table" "core_public" {
  vpc_id = aws_vpc.core.id
  tags = {
    Name = "${terraform.workspace}-public-rt"
  }
}

resource "aws_route" "core_public_internet_access" {
  route_table_id         = aws_route_table.core_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.core_ig.id
}

resource "aws_route_table_association" "core_public" {
  count          = local.core_az_count
  route_table_id = aws_route_table.core_public.id
  subnet_id      = aws_subnet.core_public[count.index].id
}

resource "aws_route_table" "core_private" {
  count  = local.core_az_count
  vpc_id = aws_vpc.core.id
  tags = {
    Name = "${terraform.workspace}-private-rt-${local.az_suffix[count.index]}"
  }
}

resource "aws_route" "core_private_internet_access" {
  count                  = local.core_az_count
  route_table_id         = aws_route_table.core_private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.core[count.index].id
}

resource "aws_route_table_association" "core_private" {
  count          = 2
  route_table_id = aws_route_table.core_private[count.index].id
  subnet_id      = aws_subnet.core_private[count.index].id
}
