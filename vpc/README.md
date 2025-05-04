# AWS VPC Terraform Module

This Terraform module creates a complete AWS VPC network infrastructure with public and private subnets, security groups, NACLs, and routing configuration. VPC peering configuration. The module is designed to be part of a multi-VPC network infrastructure.

## Features

- Creates a VPC with customizable CIDR block
- Provisions public and private subnets in a specified availability zone
- Configurable Internet Gateway deployment for public internet access
- Configures route tables for both public and private subnets
- Creates security groups with predefined rules for common traffic patterns for both public and private resources
- Implements Network ACLs (NACLs) for additional network security control
- Supports VPC peering with configurable CIDR blocks
  

## Usage

```hcl
module "vpc" {
  source = "./vpc"

  vpc_name                = "my-vpc"
  cidr_block              = "10.0.0.0/16"
  public_subnet_cidr      = "10.0.0.0/24"
  private_subnet_cidr     = "10.0.1.0/24"
  peer_vpc_cidr           = "10.1.0.0/16"  # CIDR of another VPC for peering
  availability_zone       = "us-east-1a"
  create_internet_gateway = true
}
```

## Requirements

| Name      | Version  |
| --------- | -------- |
| terraform | >= 1.0.0 |
| aws       | >= 5.0.0 |

## Inputs

| Name                    | Description                           | Type     | Default         | Required |
| ----------------------- | ------------------------------------- | -------- | --------------- | :------: |
| vpc_name                | Name of the VPC and related resources | `string` | n/a             |   yes    |
| cidr_block              | CIDR block for the VPC                | `string` | n/a             |   yes    |
| public_subnet_cidr      | CIDR block for public subnet          | `string` | n/a             |   yes    |
| private_subnet_cidr     | CIDR block for private subnet         | `string` | n/a             |   yes    |
| peer_vpc_cidr           | CIDR block of the peered VPC          | `string` | n/a             |   yes    |
| availability_zone       | Availability zone for the subnets     | `string` | `"ap-south-1a"` |    no    |
| create_internet_gateway | Whether to create an Internet Gateway | `bool`   | `true`          |    no    |

## Outputs

| Name                      | Description                       |
| ------------------------- | --------------------------------- |
| vpc_name                  | Name of the VPC                   |
| vpc_id                    | ID of the VPC                     |
| vpc_cidr_block            | CIDR block of the VPC             |
| public_subnet_id          | The ID of the public subnet       |
| private_subnet_id         | The ID of the private subnet      |
| public_security_group_id  | ID of the public security group   |
| private_security_group_id | ID of the private security group  |
| public_route_table_id     | The ID of the public route table  |
| private_route_table_id    | The ID of the private route table |

## Security Groups

### Public Security Group
- Allows inbound HTTP (port 80) from anywhere
- Allows inbound SSH (port 22) from anywhere
- Allows inbound ICMP (ping) from the peered VPC
- Allows all outbound traffic to the peered VPC

### Private Security Group
- Allows inbound SSH (port 22) from the public security group
- Allows inbound ICMP (ping) from the public security group
- Allows inbound ICMP (ping) from the peered VPC

## Network ACLs

### Public NACL
- Allows all inbound traffic
- Allows all outbound traffic

### Private NACL
- Allows inbound ICMP (ping) from the peered VPC
- Allows outbound ICMP (ping) to the peered VPC

## VPC Peering Support
- VPC Peering: Configured for secure communication between VPCs

- This module is designed to work with VPC peering. The `peer_vpc_cidr` variable should be set to the CIDR block of the VPC you want to peer with. The module configures security groups and NACLs to allow traffic between the peered VPCs.

## Notes
- The public subnet is configured to automatically assign public IPs to instances
- Egress rules are configured to allow all traffic to the peered VPC
- For production environments, consider restricting SSH access to specific IP ranges
- The security groups are configured with basic rules; customize them based on your specific requirements.
- HTTPS traffic (port 443) is commented out by default. 

## License

MIT