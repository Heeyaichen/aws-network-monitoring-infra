// Public EC2 Instance
module "ec2_instance_public" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.8.0"

  name = "public-server"

  ami                         = "ami-002f6e91abff6eb96"
  instance_type               = "t2.micro"
  key_name                    = "key pair 1"
  subnet_id                   = var.public_subnet_id          // Gets value from VPC module's output
  vpc_security_group_ids      = var.public_security_group_ids // Gets value from VPC module's output
  associate_public_ip_address = true

  create_eip = true // Creates an Elastic IP for the public instance
  eip_domain = null

  metadata_options = {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  tags = {
    Name        = "${var.vpc_name}-public-server"
    Environment = "Development"
  }
}

// Private EC2 Instance 
module "ec2_instance_private" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.8.0"

  name = "private-server"

  ami                         = "ami-002f6e91abff6eb96"
  instance_type               = "t2.micro"
  key_name                    = "key pair 1"
  subnet_id                   = var.private_subnet_id          // Gets value from VPC module's output
  vpc_security_group_ids      = var.private_security_group_ids // Gets value from VPC module's output
  associate_public_ip_address = false

  create_eip = false

  metadata_options = {
    http_endpoint               = "enabled"  // Enables the IMDSv2 endpoint
    http_tokens                 = "required" // Enforces IMDSv2
    http_put_response_hop_limit = 1          // Reduced from 2 to 1 for private instances
    instance_metadata_tags      = "disabled" // Disables access to instance tags via IMDS
  }

  tags = {
    Name        = "${var.vpc_name}-private-server"
    Environment = "Development"
  }
}


