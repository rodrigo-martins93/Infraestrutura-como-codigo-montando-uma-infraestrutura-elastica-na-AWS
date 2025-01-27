terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_launch_template" "maquina" {
  image_id          = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  tags = {
    Name = "Terraform Ansible Python"
  }
  security_group_names = [var.security_group] 
  user_data = var.production ? filebase64("ansible.sh") : ""
}

resource "aws_key_pair" "chaveSSH" {
  key_name   = var.key_name
  public_key = file("${var.public_key}")
}

resource "aws_autoscaling_group" "grupo" {
  availability_zones = ["${var.region}a", "${var.region}b"]
  name = var.auto_scaling_group_name
  max_size = var.max_size
  min_size = var.min_size
  launch_template {
    id = aws_launch_template.maquina.id
    version = "$Latest"
  }
  target_group_arns = var.production ? [aws_lb_target_group.target_group[0].arn] : []
}

resource "aws_default_subnet" "subnet_a" {
  availability_zone = "${var.region}a"
  tags = {
    Name = "subnet_a"
  }
}

resource "aws_default_subnet" "subnet_b" {
  availability_zone = "${var.region}b"
  tags = {
    Name = "subnet_b"
  }
}


resource "aws_lb" "load_balancer" { 
  internal = false  
  subnets = [aws_default_subnet.subnet_a.id, aws_default_subnet.subnet_b.id]
  # Usando o ID do Security Group encontrado
  security_groups = [aws_security_group.http_ssh_access.id]  
  count = var.production ? 1 : 0
}

resource "aws_default_vpc" "vpc" {
  tags = {
    Name = "vpc"
  }
}

resource "aws_lb_target_group" "target_group" {
  name = "targetgroup"
  port = 8000
  protocol = "HTTP"
  vpc_id = aws_default_vpc.vpc.id
  count = var.production ? 1 : 0
}


resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load_balancer[0].arn
  port = 8000
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_group[0].arn
  }
  count = var.production ? 1 : 0
}

resource "aws_autoscaling_policy" "scale-up" {
  depends_on = [aws_autoscaling_group.grupo]
  name = "scale-up"
  autoscaling_group_name = var.auto_scaling_group_name
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
  count = var.production ? 1 : 0
}
