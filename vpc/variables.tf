variable "vpc_name" {
  description = "Name of the VPC and related resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR blocks for public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR blocks for private subnet"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the subnets"
  type        = string
  default     = "ap-south-1a"
}

variable "create_internet_gateway" {
  description = "Whether to create an Internet Gateway"
  type        = bool
  default     = true
}

variable "peer_vpc_cidr" {
  description = "CIDR block of the peered VPC"
  type        = string
}
