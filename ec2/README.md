# AWS EC2 Instances Terraform Module

This Terraform module deploys a pair of EC2 instances - one in a public subnet with an Elastic IP and one in a private subnet. The module is designed to work with the VPC module in this project.

## Features

- Creates a public EC2 instance with an Elastic IP
- Creates a private EC2 instance without public internet access
- Configures IMDSv2 for enhanced security
- Applies appropriate security groups from the VPC module
- Customizable instance type
- Consistent naming and tagging

## Usage

```hcl
module "ec2_instances" {
  source = "./ec2"

  vpc_name = "my-vpc"

  // Public instance variables
  public_subnet_id          = module.vpc.public_subnet_id
  public_security_group_ids = [module.vpc.public_security_group_id]

  // Private instance variables
  private_subnet_id          = module.vpc.private_subnet_id
  private_security_group_ids = [module.vpc.private_security_group_id]
  
  // Optional parameters
  instance_type = "t2.micro"
}
```

## Requirements

| Name                               | Version  |
| ---------------------------------- | -------- |
| terraform                          | >= 1.0.0 |
| aws                                | >= 5.0.0 |
| terraform-aws-modules/ec2-instance | >= 5.8.0 |

## Inputs

| Name                       | Description                                                                   | Type           | Default      | Required |
| -------------------------- | ----------------------------------------------------------------------------- | -------------- | ------------ | :------: |
| vpc_name                   | Name of the VPC to prefix resources with                                      | `string`       | n/a          |   yes    |
| public_subnet_id           | The ID of the subnet where the public EC2 instance will be launched           | `string`       | n/a          |   yes    |
| public_security_group_ids  | List of public security group IDs to associate with the public EC2 instance   | `list(string)` | n/a          |   yes    |
| private_subnet_id          | The ID of the private subnet where the private EC2 instance will be launched  | `string`       | n/a          |   yes    |
| private_security_group_ids | List of private security group IDs to associate with the private EC2 instance | `list(string)` | n/a          |   yes    |
| instance_type              | Type of EC2 instance to launch                                                | `string`       | `"t2.micro"` |    no    |

## Outputs

| Name                   | Description                                    |
| ---------------------- | ---------------------------------------------- |
| ec2_instance_public_ip | Public IPv4 address of the public EC2 instance |

## Instance Details

### Public Instance

- **Name**: `<vpc_name>-public-server`
- **Network**: Deployed in the public subnet with a public IP
- **Elastic IP**: Automatically assigned
- **Security**: IMDSv2 enabled with required tokens
- **Access**: SSH access via the internet (port 22)

### Private Instance

- **Name**: `<vpc_name>-private-server`
- **Network**: Deployed in the private subnet without public IP
- **Security**: Enhanced IMDSv2 settings with lower hop limit
- **Access**: SSH access only from the public instance

## Security Features

This module implements several security best practices:

1. **IMDSv2 Enforcement**: Both instances require token-based access to instance metadata
2. **Reduced Hop Limit**: Private instance has a lower hop limit (1) than public instance (2)
3. **Disabled Metadata Tags**: Private instance has metadata tags access disabled
4. **Security Group Separation**: Different security groups for public and private instances

## Dependencies

This module depends on:

1. The VPC module to provide subnet IDs and security group IDs
2. The [terraform-aws-modules/ec2-instance](https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/latest) community module

## Notes

- The AMI ID is currently hardcoded as `ami-002f6e91abff6eb96` (Amazon Linux 2 in ap-south-1)
- The key pair name is hardcoded as `key pair 1` - you should modify this to match your key pair
- For production use, consider parameterizing the AMI ID and key pair name
- Both instances are tagged with `Environment = "Development"`

## Customization

To customize this module for production use:

1. Add variables for AMI ID and key pair name
2. Add support for user data scripts
3. Consider adding EBS volume customization options
4. Add more outputs like instance IDs and private IPs

## License

MIT