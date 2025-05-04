// VPC 1
module "vpc_1" {
  source = "./vpc"

  vpc_name                = var.vpc_configs.vpc1.name
  cidr_block              = var.vpc_configs.vpc1.cidr_block
  public_subnet_cidr      = var.vpc_configs.vpc1.public_subnet_cidr
  private_subnet_cidr     = var.vpc_configs.vpc1.private_subnet_cidr
  peer_vpc_cidr           = var.vpc_configs.vpc2.cidr_block // CIDR block of VPC-2 for peering
  availability_zone       = var.vpc_configs.vpc1.availability_zone
  create_internet_gateway = var.vpc_configs.vpc1.create_internet_gateway
}

// VPC 2
module "vpc_2" {
  source = "./vpc"

  vpc_name                = var.vpc_configs.vpc2.name
  cidr_block              = var.vpc_configs.vpc2.cidr_block
  public_subnet_cidr      = var.vpc_configs.vpc2.public_subnet_cidr
  private_subnet_cidr     = var.vpc_configs.vpc2.private_subnet_cidr
  peer_vpc_cidr           = var.vpc_configs.vpc1.cidr_block // CIDR block of VPC-1 for peering
  availability_zone       = var.vpc_configs.vpc2.availability_zone
  create_internet_gateway = var.vpc_configs.vpc2.create_internet_gateway
}

// IAM Role for VPC Flow Logs
// IAM Role with a trust policy that allows the VPC Flow Logs service to assume the role
resource "aws_iam_role" "vpc_flow_logs_role" {
  name        = var.flow_logs_config.role_name
  description = "Role allowing VPC Flow Logs to write to CloudWatch Logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = var.flow_logs_config.role_name
    Environment = var.environment
  }
}

// IAM Policy for VPC Flow Logs
// Created an IAM policy that grants permissions to write logs to CloudWatch
resource "aws_iam_policy" "vpc_flow_logs_policy" {
  name        = var.flow_logs_config.policy_name
  description = "Policy to allow VPC Flow Logs to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

// Attach the policy to the role
resource "aws_iam_role_policy_attachment" "vpc_flow_logs_attachment" {
  role       = aws_iam_role.vpc_flow_logs_role.name
  policy_arn = aws_iam_policy.vpc_flow_logs_policy.arn
}

// CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs_group" {
  name              = var.flow_logs_config.log_group_name
  retention_in_days = var.flow_logs_config.retention_in_days // Set retention period for logs

  tags = {
    Name        = var.flow_logs_config.log_group_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

// VPC Flow Logs for VPC-1
resource "aws_flow_log" "vpc1_flow_log" {
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs_group.arn
  log_destination_type     = "cloud-watch-logs"
  traffic_type             = var.flow_logs_config.traffic_type
  vpc_id                   = module.vpc_1.vpc_id
  iam_role_arn             = aws_iam_role.vpc_flow_logs_role.arn
  max_aggregation_interval = var.flow_logs_config.aggregation_interval
  depends_on               = [aws_iam_role_policy_attachment.vpc_flow_logs_attachment]

  tags = {
    Name        = "${var.vpc_configs.vpc1.name}-FlowLog"
    Environment = var.environment
  }
}

// VPC Peering Connection - First VPC (Requester) to Second VPC (Accepter)
resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id      = module.vpc_1.vpc_id
  peer_vpc_id = module.vpc_2.vpc_id
  auto_accept = false // Set to false when VPCs are in same account but want to follow request/accept workflow

  tags = {
    Name        = "Peering-${var.vpc_configs.vpc1.name}-to-${var.vpc_configs.vpc2.name}"
    Side        = "Requester"
    Environment = var.environment
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
