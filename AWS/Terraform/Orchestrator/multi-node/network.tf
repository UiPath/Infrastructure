### VPC Creation ###
resource "aws_vpc" "uipath" {
  cidr_block = "${var.cidr_block}"
  #### internal vpc dns resolution
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPC - ${var.application}-${var.environment}"
  }
}

### IGW for external calls ###
resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.uipath.id}"

  tags = {
    Name = "IGW-${var.application}-${var.environment}"
  }
}

### NAT gateway ###
resource "aws_eip" "nat" {
  count      = "${length(local.aws_region)}"
  vpc        = true
  depends_on = ["aws_internet_gateway.main"]
  tags       = {
    Name     = "NAT Gateway EIP - ${var.application}-${var.environment} - ${element(local.aws_region, count.index)}"
  }
}


resource "aws_nat_gateway" "main" {
  count         = "${length(local.aws_region)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  allocation_id = "${element(aws_eip.nat.*.id,count.index)}"
  depends_on    = ["aws_internet_gateway.main"]
    tags = {
    Name = "NAT Gateway - ${var.application}-${var.environment} - ${element(local.aws_region, count.index)}"
  }
}


#### SUBNET ####
resource "aws_subnet" "private" {
  count                   = "${length(local.aws_region)}"
  vpc_id                  = "${aws_vpc.uipath.id}"
  cidr_block              = "${cidrsubnet(var.cidr_block, 8, count.index)}"
  availability_zone       = "${element(local.aws_region, count.index)}"
  map_public_ip_on_launch = "${var.associate_public_ip_address}"
  tags = {
    Name = "Private subnet - ${var.application}-${var.environment} - ${element(local.aws_region, count.index)}"
    Tier = "Private"
  }
}



resource "aws_subnet" "public" {
  count                   = "${length(local.aws_region)}"
  vpc_id                  = "${aws_vpc.uipath.id}"
  cidr_block              = "${cidrsubnet(var.cidr_block, 8, count.index + length(local.aws_region))}"
  availability_zone       = "${element(local.aws_region, count.index)}"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "Public subnet - ${var.application}-${var.environment} - ${element(local.aws_region, count.index)}"
    "Tier" = "Public"
  }
}

### Provide a VPC DHCP Option Association ###
resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${aws_vpc.uipath.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.dns_resolver.id}"
}

### Set DNS resolvers so we can join a Domain Controller ###
resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = [
    "8.8.8.8",
    "8.8.4.4",
  ]
}

### Public Route Table ###
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.uipath.id}"
  route {
    cidr_block = "${var.security_cidr_block}"
    gateway_id = "${aws_internet_gateway.main.id}"
  }
    tags = {
    Name = "Public route table - ${var.application}-${var.environment}"
  }
}

resource "aws_main_route_table_association" "main" {
  vpc_id         = "${aws_vpc.uipath.id}"
  route_table_id = "${aws_route_table.public.id}"
}


### Private Route Table ###

resource "aws_route_table" "private" {
  count  = "${length(local.aws_region)}"
  vpc_id = "${aws_vpc.uipath.id}"

  tags = {
    Name = "Private route table - ${var.application}-${var.environment} - ${element(local.aws_region, count.index)}"
  }
}
resource "aws_route" "private_route" {
  count                  = "${length(local.aws_region)}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "${var.security_cidr_block}"
  nat_gateway_id         = "${element(aws_nat_gateway.main.*.id, count.index)}"
}

# Associate subnet public to public route table
resource "aws_route_table_association" "public_subnet_association" {
  count          = "${length(local.aws_region)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

# Associate subnet secondary to private route table
resource "aws_route_table_association" "private_subnet_association" {
  count          = "${length(local.aws_region)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}