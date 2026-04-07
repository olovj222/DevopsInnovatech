provider "aws" {
  region = "us-east-1"
}

# 1. VPC Y REDES
resource "aws_vpc" "principal" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "vpc-app" }
}

resource "aws_subnet" "subred_publica" {
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true 
  tags                    = { Name = "subnet-publica" } 
}

resource "aws_subnet" "subred_privada" {
  vpc_id     = aws_vpc.principal.id 
  cidr_block = "10.0.2.0/24" 
  tags       = { Name = "subnet-privada" } 
}

# 2. CONECTIVIDAD (INTERNET Y NAT)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.principal.id 
}

resource "aws_eip" "ip_nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.ip_nat.id 
  subnet_id     = aws_subnet.subred_publica.id 
  

  depends_on = [aws_internet_gateway.igw]
}

# 3. TABLAS DE RUTAS
resource "aws_route_table" "tabla_publica" {
  vpc_id = aws_vpc.principal.id 
  route {
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.igw.id 
  }
}

resource "aws_route_table_association" "asociacion_publica" {
  subnet_id      = aws_subnet.subred_publica.id 
  route_table_id = aws_route_table.tabla_publica.id 
}

resource "aws_route_table" "tabla_privada" {
  vpc_id = aws_vpc.principal.id 
  route {
    cidr_block     = "0.0.0.0/0" 
    nat_gateway_id = aws_nat_gateway.nat.id 
  }
}

resource "aws_route_table_association" "asociacion_privada" {
  subnet_id      = aws_subnet.subred_privada.id 
  route_table_id = aws_route_table.tabla_privada.id 
}

# 4. GRUPOS DE SEGURIDAD
resource "aws_security_group" "sg_app" {
  name        = "sg_multicapa" 
  description = "Grupo de seguridad para la aplicacion"
  vpc_id      = aws_vpc.principal.id 
}

# Reglas de Ingress individuales
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp" 
  cidr_blocks       = ["0.0.0.0/0"] 
  security_group_id = aws_security_group.sg_app.id
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp" 
  cidr_blocks       = ["0.0.0.0/0"] 
  security_group_id = aws_security_group.sg_app.id
}

resource "aws_security_group_rule" "backend_from_frontend" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["10.0.1.0/24"] # Solo desde subred publica
  security_group_id = aws_security_group.sg_app.id
}

resource "aws_security_group_rule" "mysql_from_backend" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp" 
  cidr_blocks       = ["10.0.2.0/24"]  # Solo desde subred privada
  security_group_id = aws_security_group.sg_app.id
}

resource "aws_security_group_rule" "outbound_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" 
  cidr_blocks       = ["0.0.0.0/0"] 
  security_group_id = aws_security_group.sg_app.id
}

# 5. LANZAMIENTO E INSTANCIAS
resource "aws_launch_template" "plantilla" {
  name_prefix   = "plantilla-app-" 
  image_id      = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  key_name      = "spe_key"

  iam_instance_profile {
    name = "LabInstanceProfile"
  }

    vpc_security_group_ids = [aws_security_group.sg_app.id]

}

resource "aws_instance" "frontend" {
  launch_template {
    id      = aws_launch_template.plantilla.id 
    version = "$Latest" 
  }
  subnet_id   = aws_subnet.subred_publica.id 
  #associate_public_ip_address = true 
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y nginx docker.io git
              systemctl start nginx
              EOF 
  tags = { Name = "frontend" } 
}

resource "aws_instance" "backend" {
  launch_template {
    id      = aws_launch_template.plantilla.id 
    version = "$Latest"
  }
  subnet_id = aws_subnet.subred_privada.id 
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y docker.io git openjdk-17-jdk
              EOF 
  tags = { Name = "backend" }
}

resource "aws_instance" "database" {
  launch_template {
    id      = aws_launch_template.plantilla.id 
    version = "$Latest" 
  }
  subnet_id = aws_subnet.subred_privada.id 
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y mysql-server
              systemctl start mysql
              EOF 
  tags = { Name = "database" } 
}

# 6. SALIDAS
output "ip_frontend" {
  description = "IP pública para acceder al sitio"
  value       = aws_instance.frontend.public_ip
}

output "ip_backend_privada" {
  description = "IP interna del backend"
  value       = aws_instance.backend.private_ip
}

output "ip_database_privada" {
  description = "IP interna de la base de datos"
  value       = aws_instance.database.private_ip
}