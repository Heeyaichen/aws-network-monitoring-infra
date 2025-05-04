# General AWS settings
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "Development"
}

# VPC settings
variable "vpc_configs" {
  description = "Configuration for VPCs"
  type = map(object({
    name                    = string
    cidr_block              = string
    public_subnet_cidr      = string
    private_subnet_cidr     = string
    availability_zone       = string
    create_internet_gateway = bool
  }))
  default = {
    vpc1 = {
      name                    = "VPC-1"
      cidr_block              = "10.1.0.0/16"
      public_subnet_cidr      = "10.1.0.0/24"
      private_subnet_cidr     = "10.1.1.0/24"
      availability_zone       = "ap-south-1a"
      create_internet_gateway = true
    },
    vpc2 = {
      name                    = "VPC-2"
      cidr_block              = "10.2.0.0/16"
      public_subnet_cidr      = "10.2.0.0/24"
      private_subnet_cidr     = "10.2.1.0/24"
      availability_zone       = "ap-south-1a"
      create_internet_gateway = true
    }
  }
}

# VPC Flow Logs settings
variable "flow_logs_config" {
  description = "Configuration for VPC Flow Logs"
  type = object({
    role_name            = string
    policy_name          = string
    log_group_name       = string
    retention_in_days    = number
    aggregation_interval = number
    traffic_type         = string
  })
  default = {
    role_name            = "VPCFlowLogsRole"
    policy_name          = "VPCFlowLogsPolicy"
    log_group_name       = "VPCFlowLogsGroup"
    retention_in_days    = 0  # Never expire
    aggregation_interval = 60 # 1 minute
    traffic_type         = "ALL"
  }
}

# VPC Peering settings
variable "vpc_peering_config" {
  description = "Configuration for VPC peering"
  type = object({
    auto_accept = bool
  })
  default = {
    auto_accept = true
  }
}
