resource "aws_security_group" "http_ssh_access" {
    name       = var.security_group
    description = var.description_sg
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        from_port   = 8000
        to_port     = 8000
        protocol    = "tcp"
    }
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
    }
    egress {
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
    }
    tags = {
        Name = "http_ssh_access"
    }
}

output "security_group_id" {
    value = aws_security_group.http_ssh_access.id
}

