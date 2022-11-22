terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.40.0"
    }

    #github = {
    # source  = "integrations/github"
    #  version = "5.9.0"
    #}
  }
}

provider "aws" {
  region = "us-east-1"
  # profile = "profile_name"
}

#provider "github" {
#  token = "XXXXXXXXXX"
#}


#data "aws_vpc" "selected" {
#    default = true
#}


resource "aws_security_group" "allow-ssh-http" {
  name = "webserver-sg"


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "webserver" {
  ami             = "ami-0f9fc25dd2506cf6d"
  instance_type   = "t2.micro"
  key_name        = "firstkey"
  security_groups = ["webserver-sg"]
  tags = {
    "Name" = "My-Web-Server of Bookstore"
  }
  user_data = <<-EOF
          #! /bin/bash
          yum update -y
          amazon-linux-extras install docker -y
          systemctl start docker
          systemctl enable docker
          usermod -a -G docker ec2-user
          curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)" \
          -o /usr/local/bin/docker-compose
          chmod +x /usr/local/bin/docker-compose  
          mkdir -p /home/ec2-user/bookstore-api
          cd /home/ec2-user/bookstore-api          
          TOKEN="XXXXXXXXXXXXXXXXXXXXXXX"
          FOLDER="https://$TOKEN@raw.githubusercontent.com/guneyfatih/bookstore/main/"
          curl -s -o bookstore-api.py -L "$FOLDER"bookstore-api.py 
          curl -s -o Dockerfile -L "$FOLDER"Dockerfile 
          curl -s -o docker-compose.yaml -L "$FOLDER"docker-compose.yaml 
          curl -s -o requirements.txt -L "$FOLDER"requirements.txt 
          docker build -t bookstore-api:latest .
          docker-compose up -d
        EOF

}


output "websiteIP" {
    value = "http://${aws_instance.webserver.public_ip}"
}