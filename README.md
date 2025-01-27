# Projeto de Infraestrutura com Terraform e Ansible

## Descrição
Este projeto configura uma infraestrutura na AWS utilizando Terraform e Ansible. Ele inclui a criação de grupos de segurança, templates de instância, grupos de autoescalamento e balanceadores de carga.

## Estrutura do Projeto:
``` yaml
.
├── .gitignore
├── .terraform.lock.hcl
├── .vscode/
│   └── settings.json
├── env/
│   ├── dev/
│   │   ├── .terraform/
│   │   ├── .terraform.lock.hcl
│   │   ├── iac-pem-useast-1.pub
│   │   ├── main.tf
│   │   ├── playbook.yml
│   │   └── terraform.tfstate
│   └── prod/
│       ├── .terraform/
│       ├── .terraform.lock.hcl
│       ├── ansible.sh
│       ├── iac-prod-west-2.pub
│       ├── main.tf
│       ├── playbook.yml
│       └── terraform.tfstate
├── infra/
│   ├── .terraform/
│   ├── .terraform.lock.hcl
│   ├── hosts.yml
│   ├── main.tf
│   ├── security_group.tf
│   └── variables.tf
└── load_locust.py
```
---

## Arquivos Principais
**"infra/main.tf"**,
define os recursos principais da infraestrutura, incluindo templates de instância, grupos de autoescalamento, sub-redes, VPCs e balanceadores de carga.
``` yaml
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
  instance_type     = var.instance_type
  key_name          = var.key_name
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
  name               = var.auto_scaling_group_name
  max_size           = var.max_size
  min_size           = var.min_size
  launch_template {
    id      = aws_launch_template.maquina.id
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
  internal        = false  
  subnets         = [aws_default_subnet.subnet_a.id, aws_default_subnet.subnet_b.id]
  security_groups = [aws_security_group.http_ssh_access.id]  
  count           = var.production ? 1 : 0
}

resource "aws_default_vpc" "vpc" {
  tags = {
    Name = "vpc"
  }
}

resource "aws_lb_target_group" "target_group" {
  name     = "targetgroup"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.vpc.id
  count    = var.production ? 1 : 0
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load_balancer[0].arn
  port              = 8000
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[0].arn
  }
  count = var.production ? 1 : 0
}

resource "aws_autoscaling_policy" "scale-up" {
  depends_on              = [aws_autoscaling_group.grupo]
  name                    = "scale-up"
  autoscaling_group_name  = var.auto_scaling_group_name
  policy_type             = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
  count = var.production ? 1 : 0
}
```

**"infra/security_group.tf"**,
configura um grupo de segurança que permite todo o tráfego de entrada e saída.
``` yaml
resource "aws_security_group" "http_ssh_access" {
  name        = "http_ssh_access"
  description = "Allow HTTP and SSH access"
  vpc_id      = aws_default_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "http_ssh_access"
  }
}
```
**"infra/variables.tf"**,
define as variáveis utilizadas no projeto, como região, tipo de instância, AMI, grupo de segurança, etc.
``` yaml
variable "region" {
  description = "The AWS region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The instance type to use"
  type        = string
  default     = "t2.micro"
}

variable "ami" {
  description = "The AMI to use for the instance"
  type        = string
  default     = "ami-0e2c8caa4b6378d8c"
}

variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = "iac-pem-useast-1.pem"
}

variable "public_key" {
  description = "The path to the public key file"
  type        = string
  default     = "iac-pem-useast-1.pub"
}

variable "security_group" {
  description = "The name of the security group"
  type        = string
  default     = "dev"
}

variable "auto_scaling_group_name" {
  description = "The name of the auto scaling group"
  type        = string
  default     = "DEV"
}

variable "max_size" {
  description = "The maximum size of the auto scaling group"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "The minimum size of the auto scaling group"
  type        = number
  default     = 1
}

variable "production" {
  description = "Is this a production environment?"
  type        = bool
  default     = false
}
```

**"env/prod/ansible.sh"**,
script utilizado para configurar o ambiente de produção com Ansible. Instala dependências, clona o repositório e configura o servidor.
``` yaml
#!/bin/bash
cd /home/ubuntu

# Baixa e instala o pip para Python3
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python3 get-pip.py

# Instala o Ansible
sudo python3 -m pip install ansible

# Cria o playbook Ansible
tee -a playbook.yml > /dev/null <<EOT
- hosts: localhost
  become: yes
  tasks:
    - name: Instalando o python3, virtualenv
      apt:
        pkg:
          - python3
          - python3-venv
        state: present
EOT

# Executa o playbook Ansible
ansible-playbook playbook.yml
```

**"load_locust.py"**,
script para testes de carga utilizando Locust.
``` yaml
from locust import HttpUser, TaskSet, task, between

class UserBehavior(TaskSet):
    @task(1)
    def index(self):
        self.client.get("/")

class WebsiteUser(HttpUser):
    tasks = [UserBehavior]
    wait_time = between(5, 15)
```

## Como Usar:
Pré-requisitos
- Terraform instalado
- AWS CLI configurado
- Ansible instalado

1.Passos
Clone o repositório:
```yaml
git clone <URL_DO_REPOSITORIO>
cd <NOME_DO_REPOSITORIO>
```

2.Inicialize o Terraform:
```yaml
terraform init
```

3.Aplique a configuração do Terraform:
```
terraform apply
```

4.Para o ambiente de produção, o script ansible.sh será executado automaticamente para configurar o servidor.
Sendo necessário estar no diretório de desenvolvimento ou produção para aplicar o terraform.






