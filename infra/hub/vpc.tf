resource "aws_vpc" "hub" {
  cidr_block = local.hub_vpc_cidr
  tags = {
    Name = "${local.hub_name_prefix}-vpc"
  }
}

resource "aws_subnet" "hub" {
  count             = local.hub_az_count
  vpc_id            = aws_vpc.hub.id
  cidr_block        = cidrsubnet(aws_vpc.hub.cidr_block, 8, count.index)
  availability_zone = "${local.region}${local.az_suffix[count.index]}"

  tags = {
    Name = "${local.hub_name_prefix}-private-subnet-${local.az_suffix[count.index]}"
  }
}

resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id
  tags = {
    Name = "${local.hub_name_prefix}-internet-gateway"
  }
}

resource "aws_route_table" "hub" {
  count  = local.hub_az_count
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "${local.hub_name_prefix}-private-rt-${local.az_suffix[count.index]}"
  }
}

resource "aws_route_table_association" "hub" {
  count          = local.hub_az_count
  subnet_id      = aws_subnet.hub[count.index].id
  route_table_id = aws_route_table.hub[count.index].id
}

resource "aws_route" "hub_internet_access" {
  count                  = local.hub_az_count
  route_table_id         = aws_route_table.hub[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.hub.id
}

resource "aws_ec2_transit_gateway" "hub" {
  description                     = "${local.hub_name_prefix} transit gateway"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "${local.hub_name_prefix}-transit-gateway"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  subnet_ids         = aws_subnet.hub[*].id
  vpc_id             = aws_vpc.hub.id
  transit_gateway_id = aws_ec2_transit_gateway.hub.id

  tags = {
    Name = "${local.hub_name_prefix}-tgw-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "project_vpcs" {
  for_each = toset(local.core_workspaces)

  transit_gateway_id = aws_ec2_transit_gateway.hub.id
  vpc_id             = local.core_vpc_ids[each.key]
  subnet_ids         = local.core_private_subnet_ids[each.key]

  tags = {
    Name = "${local.hub_name_prefix}-tgw-${each.key}-attachment"
  }
}

# Transit Gateway Route Table
resource "aws_ec2_transit_gateway_route_table" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.hub.id

  tags = {
    Name = "${local.hub_name_prefix}-tgw-rt"
  }
}

# Route in Transit Gateway Route Table for VPN clients
resource "aws_ec2_transit_gateway_route" "vpn_clients" {
  destination_cidr_block         = local.vpn_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

# Associate the Transit Gateway Route Table with VPC attachments
resource "aws_ec2_transit_gateway_route_table_association" "hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route_table_association" "project_vpcs" {
  for_each = toset(local.core_workspaces)

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.project_vpcs[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

# Propagate routes from VPC attachments to the Transit Gateway Route Table
resource "aws_ec2_transit_gateway_route_table_propagation" "hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "project_vpcs" {
  for_each = toset(local.core_workspaces)

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.project_vpcs[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_route" "from_core_private_to_vpn_clients" {
  count                  = length(local.flattened_core_route_tables)
  route_table_id         = local.flattened_core_route_tables[count.index].rt_id
  destination_cidr_block = local.vpn_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.hub.id
}

resource "aws_route" "from_core_private_to_openvpn_vpc" {
  count                  = length(local.flattened_core_route_tables)
  route_table_id         = local.flattened_core_route_tables[count.index].rt_id
  destination_cidr_block = aws_vpc.hub.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.hub.id
}



resource "aws_route" "from_core_public_to_vpn_clients" {
  for_each               = toset(local.core_workspaces)
  route_table_id         = local.core_public_route_table_id[each.key]
  destination_cidr_block = local.vpn_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.hub.id
}

resource "aws_route" "to_openvpn_vpc" {
  for_each               = toset(local.core_workspaces)
  route_table_id         = local.core_public_route_table_id[each.key]
  destination_cidr_block = aws_vpc.hub.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.hub.id
}
