variable "public_subnet_id" {
  description = "The ID of the subnet where the EC2 instance will be launched"
  type        = string
}

variable "public_security_group_ids" {
  description = "List of public security group IDs to associate with the EC2 instance"
  type        = list(string)
}

variable "private_subnet_id" {
  description = "The ID of the private subnet where the EC2 instance will be launched"
  type        = string
}

variable "private_security_group_ids" {
  description = "List of private security group IDs to associate with the EC2 instance"
  type        = list(string)
}

variable "vpc_name" {
  description = "Name of the VPC to prefix resources with"
  type        = string
}

variable "instance_type" {
  description = "Type of EC2 instance to launch"
  type        = string
  default     = "t2.micro"
}
