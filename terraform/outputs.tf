output "ec2_public_ip" {
  value       = aws_instance.dream_ec2.public_ip
  description = "The public IP address of the EC2 instance"
}

output "public_dns" {
  value       = aws_instance.dream_ec2.public_dns
  description = "The public DNS name of the EC2 instance"
}

output "security_group_id" {
  value       = aws_security_group.dream_sg.id
  description = "The ID of the security group"
}

output "key_pair_name" {
  value       = var.key_name
  description = "The name of the EC2 key pair"
}

output "ssh_command" {
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.dream_ec2.public_ip}"
  description = "SSH command to connect to the EC2 instance"
}

output "vpc_id" {
  value       = aws_vpc.dream_vpc.id
  description = "The ID of the VPC"
}