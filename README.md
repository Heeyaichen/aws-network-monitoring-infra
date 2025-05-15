# AWS Multi-VPC Network Infrastructure with Terraform

This project provides an automated solution for deploying a secure multi-VPC network infrastructure on AWS using Terraform. It creates two interconnected VPCs with public and private subnets, VPC peering, flow logging, and EC2 instances, enabling secure and monitored communication between isolated network environments.



## Architecture Overview

![Image](https://github.com/user-attachments/assets/314a0797-2535-4c10-b6b6-a90bf83e0330)

This infrastructure implements AWS networking best practices including:
- Isolated network segments with public and private subnets
- Secure VPC peering for inter-VPC communication
- Comprehensive network monitoring with VPC Flow Logs to CloudWatch
- Granular access control with security groups and NACLs
- Automated state management with S3 and DynamoDB backend

## Module Structure

The project is organized into the following modules:

- **Root Module**: Orchestrates the entire infrastructure deployment
- **[VPC Module](./vpc/README.md)**: Creates VPC, subnets, security groups, and NACLs
- **[EC2 Module](./ec2/README.md)**: Deploys EC2 instances in public and private subnets

## Features

### Network Infrastructure
- Two fully configured VPCs with public and private subnets
- VPC peering connection for inter-VPC communication
- Internet gateways for public internet access
- Security groups with least-privilege access controls
- Network ACLs for subnet-level security

### Monitoring and Logging
- CloudWatch Log Group for VPC Flow Logs
- Customizable log retention periods
- Traffic monitoring for security and compliance

### Compute Resources
- EC2 instances in both public and private subnets for each VPC
- Enhanced security with IMDSv2 enforcement
- Elastic IPs for public instances

### Security
- IAM roles and policies with least privilege
- Security groups with specific ingress/egress rules
- Network ACLs for additional network security
- VPC Flow Logs for network traffic monitoring

## Prerequisites

- AWS CLI installed and configured with appropriate credentials
- Terraform >= 1.0.0
- AWS account with appropriate permissions
- Key pair created in AWS for EC2 instance access

## Quick Start
### 1. Authenticate Terraform with AWS
- Choose one of the following authentication methods:

#### Option A: AWS Shared Configuration Files
#### AWS CLI uses two main files:
- `~/.aws/config` - Contains configuration settings like region, output format
- `~/.aws/credentials` - Contains your access keys

```bash
# Create the .aws directory (if it doesn't exist)
# Windows
mkdir %USERPROFILE%\.aws

# macOS/Linux
mkdir -p ~/.aws

# Create/edit the credentials file
# Windows
notepad %USERPROFILE%\.aws\credentials

# macOS/Linux
nano ~/.aws/credentials

# Add your credentials
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY

# Create/edit the config file
# Windows
notepad %USERPROFILE%\.aws\config

# macOS/Linux
nano ~/.aws/config

# Add your configuration
[default]
region = <your-aws-region>
output = json
```
#### Option B: AWS CLI Configure
```bash
aws configure
# Then enter your access key, secret key, region, and output format when prompted
```

#### Option C: Environment Variables
```bash
# Windows
set AWS_ACCESS_KEY_ID=your_access_key
set AWS_SECRET_ACCESS_KEY=your_secret_key
set AWS_REGION=<your-aws-region>

# macOS/Linux
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_REGION=<your-aws-region>
```
#### Option D: AWS IAM Roles
- For production environments, consider using AWS IAM Roles with AssumeRole.

#### Option E: AWS SSO Integration 
- For enterprise environments, consider integrating with AWS SSO.

Learn more about authentication methods in the [Terraform AWS Provider Documentation.](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)


### 2. Set Up the Terraform Backend

First, set up the S3 bucket and DynamoDB table for Terraform state management:

```bash
# Make the script executable
chmod +x setup_terraform_backend.sh

# Run the script
./setup-remote-state.sh
```
This script creates:
- An S3 bucket for state storage with versioning and encryption
and DynamoDB table for state locking
- Remote state storage ensures team collaboration

### 3. Initialize Terraform
```bash
# For a new project (no existing state)
terraform init

# For existing project with local state files
terraform init -migrate-state
```

### 4. Deploy the Infrastructure
```bash
# Preview the changes
terraform plan

# Apply the configuration
terraform apply -auto-approve
```

## Detailed Component Documentation

### VPC Peering

The infrastructure establishes a VPC peering connection between VPC-1 and VPC-2, allowing direct communication between resources in both VPCs:

```hcl
resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id      = module.vpc_1.vpc_id
  peer_vpc_id = module.vpc_2.vpc_id
  auto_accept = false
  
  tags = {
    Name        = "Peering-${var.vpc_configs.vpc1.name}-to-${var.vpc_configs.vpc2.name}"
    Side        = "Requester"
    Environment = var.environment
  }
}
```

Routes are automatically configured in all route tables to enable traffic flow between the VPCs.

### VPC Flow Logs

VPC Flow Logs are configured to capture network traffic for VPC-1:

```hcl
resource "aws_flow_log" "vpc1_flow_log" {
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs_group.arn
  log_destination_type     = "cloud-watch-logs"
  traffic_type             = var.flow_logs_config.traffic_type
  vpc_id                   = module.vpc_1.vpc_id
  iam_role_arn             = aws_iam_role.vpc_flow_logs_role.arn
  max_aggregation_interval = var.flow_logs_config.aggregation_interval
  
  tags = {
    Name        = "${var.vpc_configs.vpc1.name}-FlowLog"
    Environment = var.environment
  }
}
```

The logs are stored in CloudWatch and can be used for security analysis, troubleshooting, and compliance.

## Module Details

### VPC Module

The [VPC module](./vpc/README.md) creates a complete VPC infrastructure including:

- VPC with custom CIDR block
- Public and private subnets
- Internet Gateway
- Route tables
- Security groups
- Network ACLs

For detailed documentation, see the [VPC Module README](./vpc/README.md).

### EC2 Module

The [EC2 module](./ec2/README.md) deploys EC2 instances in both public and private subnets:

- Public instance with Elastic IP
- Private instance without public internet access
- Security group associations
- IMDSv2 configuration for enhanced security

For detailed documentation, see the [EC2 Module README](./ec2/README.md).

## Network Data Flow
The infrastructure enables secure communication between two VPCs through VPC peering, with traffic flowing through public and private subnets. VPC Flow Logs capture all network traffic for monitoring and analysis.

```ascii
                    VPC Peering
    VPC-1 <-------------------------> VPC-2
     |                                 |
     |                                 |
  Internet                         Internet
  Gateway                          Gateway
     |                                 |
     v                                 v
Public Subnet <---> Private Subnet  Public Subnet <---> Private Subnet
     |                |                |                |
     v                v                v                v
  EC2 Instance    EC2 Instance     EC2 Instance     EC2 Instance
```

Key Component Interactions:
1. Internet traffic flows through Internet Gateways to public subnets
2. Private subnets can communicate with public subnets in the same VPC
3. VPC peering enables direct communication between VPCs
4. Security groups control instance-level access
5. NACLs provide subnet-level security
6. VPC Flow Logs capture all network traffic
7. CloudWatch stores and manages flow logs

## Customization

### Adding More VPCs

To add more VPCs, extend the `vpc_configs` variable in your `terraform.tfvars` file:

```hcl
vpc_configs = {
  vpc1 = { ... },
  vpc2 = { ... },
  vpc3 = {
    name                    = "VPC-3"
    cidr_block              = "10.3.0.0/16"
    public_subnet_cidr      = "10.3.0.0/24"
    private_subnet_cidr     = "10.3.1.0/24"
    availability_zone       = "ap-south-1a"
    create_internet_gateway = true
  }
}
```

Then update the main.tf file to create the new VPC and establish peering connections.

### Enabling Flow Logs for Additional VPCs

To enable flow logs for VPC-2 or additional VPCs, add a new flow log resource:

```hcl
resource "aws_flow_log" "vpc2_flow_log" {
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs_group.arn
  log_destination_type     = "cloud-watch-logs"
  traffic_type             = var.flow_logs_config.traffic_type
  vpc_id                   = module.vpc_2.vpc_id
  iam_role_arn             = aws_iam_role.vpc_flow_logs_role.arn
  max_aggregation_interval = var.flow_logs_config.aggregation_interval
  
  tags = {
    Name        = "${var.vpc_configs.vpc2.name}-FlowLog"
    Environment = var.environment
  }
}
```
## Testing and Verification

### Test VPC Peering Connection

After deploying the infrastructure, we can verify that the VPC peering connection is working correctly:

1. Connect to VPC-1's public EC2 instance ("public-server") using EC2 Instance Connect in the AWS Console
2. Obtain the private IP address of VPC-2's public EC2 instance from the AWS Console or Terraform outputs
3. Run the following command to test connectivity across the VPC peering connection:
   ```bash
   ping <VPC-2's Public EC2 instance's Private IPv4 address>
   ```
   ![Image](https://github.com/user-attachments/assets/86e00cd1-de4b-47f5-a46d-5a8b6f6ff4e5)
   
5. We should see successful ping replies, confirming that traffic is flowing between the VPCs through the peering connection. The instances are communicating via their private IP addresses across VPCs.

### Analyze VPC Flow Logs
To verify, review the VPC Flow Logs to monitor and analyze network traffic:
#### 1. Access CloudWatch Logs:
- Navigate to CloudWatch in the AWS Console
- Go to Log groups > VPCFlowLogsGroup > Log Streams
- Select the log stream for VPC-1
  
![Image](https://github.com/user-attachments/assets/6f410d26-27be-4f7d-bf21-a494869b6662)

#### 2. Examine the log events:
- We should see entries for the ping traffic we generated in the previous step
- The logs will show source and destination IP addresses, ports, protocol (ICMP for ping), and whether the traffic was accepted or rejected
- Look for records with source and destination IPs matching the VPC CIDR blocks
- Flow logs include: source/destination IPs, ports, protocol, packet counts, etc.
#### 3. Analyze traffic patterns:
- Identify the ICMP traffic (protocol 1) from the ping test
- Verify the source IP (VPC-1 instance) and destination IP (VPC-2 instance)
- Confirm that traffic was accepted by security groups and NACLs

Flow log entries confirm that the traffic is flowing between the VPCs as expected through the peering connection.
These logs are valuable for security analysis, troubleshooting network connectivity issues, and compliance reporting.

## Troubleshooting

### VPC Peering Issues

- **Error**: "VPC Peering Connection not in 'active' state"
  ```bash
  # Verify peering connection status
  aws ec2 describe-vpc-peering-connections --region ap-south-1
  ```
  **Solution**: Ensure both VPCs exist and auto-accept is enabled

### Flow Logs Issues

- **Error**: "InvalidParameterException: The specified log group does not exist"
  ```bash
  # Verify log group exists
  aws logs describe-log-groups --region ap-south-1
  ```
  **Solution**: Ensure IAM roles and policies are correctly configured

### EC2 Connection Issues

- **Error**: Unable to SSH into private instances
- **Solution**: Ensure we're connecting through the public instance as a bastion host

## Security Considerations

1. **Least Privilege**: The IAM roles and policies follow the principle of least privilege
2. **Network Isolation**: Private subnets are not directly accessible from the internet
3. **Traffic Monitoring**: VPC Flow Logs capture all network traffic for security analysis
4. **IMDSv2 Enforcement**: EC2 instances require token-based metadata access
5. **Security Groups**: Inbound and outbound traffic is restricted based on specific rules

## Contributing
Contributions to this project are welcome. Please follow these steps to contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature-name`)
3. Commit your changes with clear, descriptive messages
4. Ensure all Terraform configurations pass validation (`terraform validate`)
5. Update documentation as needed
6. Submit a Pull Request with a comprehensive description of changes

For major changes or features, please open an issue first to discuss what we would like to change.

## License

MIT

## Authors

Heeyaichen Konsam
