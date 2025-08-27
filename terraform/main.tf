data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical (official Ubuntu owner).
}

resource "aws_vpc" "dream_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "dream-vpc"
  }
}

resource "aws_subnet" "dream_subnet" {
  vpc_id                  = aws_vpc.dream_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true # Automatically assign public IP to instances in this subnet.
  tags = {
    Name = "dream-subnet"
  }
}

resource "aws_internet_gateway" "dream_igw" {
  vpc_id = aws_vpc.dream_vpc.id
  tags = {
    Name = "dream-igw"
  }
}

resource "aws_route_table" "dream_rt" {
  vpc_id = aws_vpc.dream_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dream_igw.id
  }
  tags = {
    Name = "dream-rt"
  }
}

resource "aws_route_table_association" "dream_subnet_association" {
  subnet_id      = aws_subnet.dream_subnet.id
  route_table_id = aws_route_table.dream_rt.id
}

resource "aws_security_group" "dream_sg" {
  name        = "dream-sg"
  description = "Security group for Dream Vacation App EC2"
  vpc_id      = aws_vpc.dream_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (restrict to your IP in production).
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP for frontend.
  }

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow backend port as per your notes.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic.
  }
}

resource "aws_instance" "dream_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.dream_subnet.id
  vpc_security_group_ids = [aws_security_group.dream_sg.id]
  key_name               = var.key_name
  user_data              = <<-EOF
    #!/bin/bash
    set -e

    # Install Docker
    sudo apt update -y
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker ubuntu

    # Install Docker Compose (latest version as of 2025; update if needed)
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Install CloudWatch Agent
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

    # Configure CloudWatch Agent for CPU metrics
    sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
    cat <<'EOC' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    {
      "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
      },
      "metrics": {
        "append_dimensions": {
          "InstanceId": "$${aws:InstanceId}"
        },
        "metrics_collected": {
          "cpu": {
            "measurement": [
              "cpu_usage_idle",
              "cpu_usage_iowait",
              "cpu_usage_user",
              "cpu_usage_system"
            ],
            "metrics_collection_interval": 60,
            "totalcpu": false
          }
        }
      }
    }
    EOC

    # Start CloudWatch Agent
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
  EOF

  tags = {
    Name = "dream-ec2"
  }
}

resource "aws_cloudwatch_metric_alarm" "dream_cpu_alarm" {
  alarm_name          = "dream-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "This alarm triggers if CPU utilization exceeds 70% for 2 consecutive 1-minute periods."
  dimensions = {
    InstanceId = aws_instance.dream_ec2.id
  }
  # Note: No alarm actions specified (e.g., no SNS); add if needed for notifications.
}