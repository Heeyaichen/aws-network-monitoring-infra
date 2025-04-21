output "ec2_instance_public_ip" {
  description = "Public IPv4 address of the EC2 instance"
  value       = module.ec2_instance_public.public_ip
}
