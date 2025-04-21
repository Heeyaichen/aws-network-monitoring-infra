// VPC 1
module "vpc_1" {
  source = "./vpc"

  vpc_name                = "VPC-1"
  cidr_block              = "10.1.0.0/16"
  public_subnet_cidr      = "10.1.0.0/24"
  private_subnet_cidr     = "10.1.1.0/24"
  peer_vpc_cidr           = "10.2.0.0/16" // CIDR block of VPC-2 for peering
  availability_zone       = "ap-south-1a"
  create_internet_gateway = true
}

// VPC 2
module "vpc_2" {
  source = "./vpc"

  vpc_name                = "VPC-2"
  cidr_block              = "10.2.0.0/16"
  public_subnet_cidr      = "10.2.0.0/24"
  private_subnet_cidr     = "10.2.1.0/24"
  peer_vpc_cidr           = "10.1.0.0/16" // CIDR block of VPC-1 for peering
  availability_zone       = "ap-south-1a"
  create_internet_gateway = true // Optional: only create IGW for first VPC
}

// VPC Peering Connection - First VPC (Requester) to Second VPC (Accepter)
resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id      = module.vpc_1.vpc_id
  peer_vpc_id = module.vpc_2.vpc_id
  auto_accept = false // Set to false when VPCs are in same account but want to follow request/accept workflow

  tags = {
    Name = "VPC Peering between VPC-1 and VPC-2"
    Side = "Requester"
  }
}

// VPC Peering Connection Accepter
resource "aws_vpc_peering_connection_accepter" "peer_accepter" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  auto_accept               = true

  tags = {
    Name = "VPC Peering between VPC-1 and VPC-2"
    Side = "Accepter"
  }
}

// Routes for VPC Peering
// This section adds routes to the route tables of both VPCs to allow traffic to flow between them
// The routes are added to the public and private route tables of both VPCs
// The destination CIDR blocks are the CIDR blocks of the other VPC
// The VPC peering connection ID is used to route traffic through the peering connection

// VPC1 to VPC2 routes (2 routes)
resource "aws_route" "vpc1_to_vpc2_public" {
  route_table_id            = module.vpc_1.public_route_table_id
  destination_cidr_block    = module.vpc_2.vpc_cidr_block // 10.2.0.0/16
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  depends_on                = [aws_vpc_peering_connection_accepter.peer_accepter] // Ensure the peering connection is accepted before adding routes
}

resource "aws_route" "vpc1_to_vpc2_private" {
  route_table_id            = module.vpc_1.private_route_table_id
  destination_cidr_block    = module.vpc_2.vpc_cidr_block // 10.2.0.0/16
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  depends_on                = [aws_vpc_peering_connection_accepter.peer_accepter] // Ensure the peering connection is accepted before adding routes
}

// VPC2 to VPC1 routes (2 routes)
resource "aws_route" "vpc2_to_vpc1_public" {
  route_table_id            = module.vpc_2.public_route_table_id
  destination_cidr_block    = module.vpc_1.vpc_cidr_block // 10.1.0.0/16
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  depends_on                = [aws_vpc_peering_connection_accepter.peer_accepter]
}

resource "aws_route" "vpc2_to_vpc1_private" {
  route_table_id            = module.vpc_2.private_route_table_id
  destination_cidr_block    = module.vpc_1.vpc_cidr_block // 10.1.0.0/16
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  depends_on                = [aws_vpc_peering_connection_accepter.peer_accepter]
}

// Compute Module
// This module call creates two EC2 instances each in the public and private subnets of VPC-1
module "vpc1_ec2s" {
  source = "./ec2"

  vpc_name = module.vpc_1.vpc_name

  // Public instance variables
  public_subnet_id          = module.vpc_1.public_subnet_id           // Uses output from VPC module
  public_security_group_ids = [module.vpc_1.public_security_group_id] // Uses output from VPC module

  // Private instance variables
  private_subnet_id          = module.vpc_1.private_subnet_id
  private_security_group_ids = [module.vpc_1.private_security_group_id]
}

// This module call creates two EC2 instances each in the public and private subnets of VPC-2
module "vpc2_ec2s" {
  source = "./ec2"

  vpc_name = module.vpc_2.vpc_name

  // Public instance variables
  public_subnet_id          = module.vpc_2.public_subnet_id           // Uses output from VPC module
  public_security_group_ids = [module.vpc_2.public_security_group_id] // Uses output from VPC module

  // Private instance variables
  private_subnet_id          = module.vpc_2.private_subnet_id
  private_security_group_ids = [module.vpc_2.private_security_group_id]
}
