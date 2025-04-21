// Virtual Private Cloud (VPC) Configuration
resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = var.vpc_name
  }
}

// Public Subnet Configuration
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone

  tags = {
    Name = "${var.vpc_name}-public-subnet"
  }
}

// Private Subnet Configuration 
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = false
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone

  tags = {
    Name = "${var.vpc_name}-private-subnet"
  }
}


// Internet Gateway Configuration
resource "aws_internet_gateway" "main" {
  count  = var.create_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

// Route Table Configuration
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}

// Route to Internet Gateway
resource "aws_route" "public_internet_gateway" {
  count                  = var.create_internet_gateway ? 1 : 0
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}

// Route Table Associations 
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}

// Public Security Group Configuration
resource "aws_security_group" "public_sg" {
  name        = "${var.vpc_name}-public-sg"
  description = "Security Group for Public Subnet Resources"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-public-sg"
  }
}

// Ingress Rule for HTTP (Port 80)
resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  description       = "Allow HTTP traffic from anywhere"
}

// Ingress Rule for SSH (Port 22)
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  description       = "Allow SSH traffic from anywhere"
}

// Ingress Rule for ICMPv4 (Ping) traffic 
resource "aws_vpc_security_group_ingress_rule" "allow_icmp_peering" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4         = var.peer_vpc_cidr // CIDR block of the peered VPC
  ip_protocol       = "icmp"
  from_port         = -1 // All ICMP types
  to_port           = -1 // All ICMP codes
  description       = "Allow ICMP (ping) traffic from peered VPC"
}

// Egress Rule for All Traffic to Peered VPC
resource "aws_vpc_security_group_egress_rule" "allow_all_peering" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4         = var.peer_vpc_cidr // CIDR block of the peered VPC
  ip_protocol       = "-1"              // All protocols
  description       = "Allow all traffic to peered VPC"
}

// Private Security Group Configuration
resource "aws_security_group" "private_sg" {
  name        = "${var.vpc_name}-private-sg"
  description = "Security Group for Private Subnet Resources"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-private-sg"
  }
}

// Ingress Rule for SSH (Port 22)
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id            = aws_security_group.private_sg.id
  referenced_security_group_id = aws_security_group.public_sg.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
  description                  = "Allow SSH traffic from public security group"
}

// Ingress Rule for ICMPv4 (Ping) traffic from the Public Subnet
resource "aws_vpc_security_group_ingress_rule" "allow_icmpv4" {
  security_group_id            = aws_security_group.private_sg.id
  referenced_security_group_id = aws_security_group.public_sg.id
  ip_protocol                  = "icmp"
  from_port                    = -1 // All ICMP types
  to_port                      = -1 // All ICMP codes
  description                  = "Allow ICMP (ping) traffic from public security group"
}

// Allow ICMP from peered VPC to private instances
resource "aws_vpc_security_group_ingress_rule" "allow_icmp_peering_private" {
  security_group_id = aws_security_group.private_sg.id
  cidr_ipv4         = var.peer_vpc_cidr
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  description       = "Allow ICMP traffic from peered VPC"
}

// Network Access Control List (NACL) Configuration for Public Subnet
resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.main.id

  // Public Subnet Association
  subnet_ids = [aws_subnet.public.id]

  // Allow all inbound traaffic from the Internet
  ingress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1" // All protocols
    action     = "allow"
    rule_no    = 100
    cidr_block = "0.0.0.0/0" // Allow all inbound traffic from the Internet
  }

  // Allow all outbound traffic to the Internet
  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1" // All protocols
    action     = "allow"
    rule_no    = 100
    cidr_block = "0.0.0.0/0" // Allow all outbound traffic to the Internet
  }

  tags = {
    Name = "${var.vpc_name}-public-nacl"
  }
}

// Network Access Control List (NACL) Configuration for Private Subnet
resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.main.id

  // Private Subnet Association
  subnet_ids = [aws_subnet.private.id]

  tags = {
    Name = "${var.vpc_name}-private-nacl"
  }
}

// Allow inbound ICMPv4 Echo Reply (Ping) from Peered VPC
resource "aws_network_acl_rule" "allow_icmp_peering_private_ingress" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 110
  protocol       = "icmp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = var.peer_vpc_cidr // CIDR block of the peered VPC
  icmp_type      = -1                // All ICMP types
  icmp_code      = -1                // All ICMP codes
}

// Allow outbound ICMPv4 Echo Reply (Ping) to Peered VPC
resource "aws_network_acl_rule" "allow_icmp_peering_private_egress" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 110
  protocol       = "icmp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = var.peer_vpc_cidr // CIDR block of the peered VPC
  icmp_type      = -1                // All ICMP types
  icmp_code      = -1                // All ICMP codes
}
