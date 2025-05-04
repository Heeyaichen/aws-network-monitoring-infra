# VPC Outputs
output "vpc_ids" {
  description = "IDs of the created VPCs"
  value = {
    vpc1 = module.vpc_1.vpc_id
    vpc2 = module.vpc_2.vpc_id
  }
}

output "vpc_cidr_blocks" {
  description = "CIDR blocks of the created VPCs"
  value = {
    vpc1 = module.vpc_1.vpc_cidr_block
    vpc2 = module.vpc_2.vpc_cidr_block
  }
}

# Subnet Outputs
output "subnet_ids" {
  description = "IDs of the created subnets"
  value = {
    vpc1_public  = module.vpc_1.public_subnet_id
    vpc1_private = module.vpc_1.private_subnet_id
    vpc2_public  = module.vpc_2.public_subnet_id
    vpc2_private = module.vpc_2.private_subnet_id
  }
}

# Security Group Outputs
output "security_group_ids" {
  description = "IDs of the created security groups"
  value = {
    vpc1_public  = module.vpc_1.public_security_group_id
    vpc1_private = module.vpc_1.private_security_group_id
    vpc2_public  = module.vpc_2.public_security_group_id
    vpc2_private = module.vpc_2.private_security_group_id
  }
}

# EC2 Instance Outputs
output "ec2_instance_public_ips" {
  description = "Public IPs of the EC2 instances"
  value = {
    vpc1 = module.vpc1_ec2s.ec2_instance_public_ip
    vpc2 = module.vpc2_ec2s.ec2_instance_public_ip
  }
}

# VPC Peering Outputs
output "vpc_peering_connection_id" {
  description = "ID of the VPC peering connection"
  value       = aws_vpc_peering_connection.vpc_peering.id
}

# VPC Flow Logs Outputs
output "flow_logs_role_arn" {
  description = "ARN of the IAM role for VPC Flow Logs"
  value       = aws_iam_role.vpc_flow_logs_role.arn
}

output "flow_logs_group_arn" {
  description = "ARN of the CloudWatch Log Group for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs_group.arn
}

output "vpc1_flow_log_id" {
  description = "ID of the VPC Flow Log for VPC-1"
  value       = aws_flow_log.vpc1_flow_log.id
}
