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
          - virtualenv
        update_cache: yes

    - name: Clonar o repositório
      git:
        repo: 'https://github.com/alura-cursos/clientes-leo-api.git'
        dest: /home/ubuntu/tcc
        version: master
        force: yes

    - name: Criar o ambiente virtual e instalar dependências
      shell: |
        python3 -m venv /home/ubuntu/tcc/venv
        . /home/ubuntu/tcc/venv/bin/activate
        pip install -r /home/ubuntu/tcc/requirements.txt

    - name: Alterar o ALLOWED_HOSTS no settings
      lineinfile:
        path: /home/ubuntu/tcc/setup/settings.py
        regexp: 'ALLOWED_HOSTS'
        line: 'ALLOWED_HOSTS = ["*"]'
        backrefs: yes

    - name: Configurar o banco de dados
      shell: |
        . /home/ubuntu/tcc/venv/bin/activate
        python /home/ubuntu/tcc/manage.py migrate

    - name: Carregar os dados iniciais
      shell: |
        . /home/ubuntu/tcc/venv/bin/activate
        python /home/ubuntu/tcc/manage.py loaddata clientes.json

    - name: Iniciar o servidor
      shell: |
        . /home/ubuntu/tcc/venv/bin/activate
        nohup python /home/ubuntu/tcc/manage.py runserver 0.0.0.0:8000 &
EOT

ansible-playbook playbook.yml
