### Establish Provider and Access ###

provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

### VPC Creation ###
resource "aws_vpc" "uipath" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

# Declare the data source
data "aws_availability_zones" "available" {
}

### Create Subnet for all of our resources ###
resource "aws_subnet" "primary" {
  vpc_id                  = aws_vpc.uipath.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_subnet" "secondary" {
  vpc_id                  = aws_vpc.uipath.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

### IGW for external calls ###
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.uipath.id

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

### Route Table ###
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.uipath.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

### Main Route Table ###
resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.uipath.id
  route_table_id = aws_route_table.main.id
}

### Provide a VPC DHCP Option Association ###
resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.uipath.id
  dhcp_options_id = aws_vpc_dhcp_options.dns_resolver.id
}

### Set DNS resolvers so we can join a Domain Controller ###
resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = [
    "8.8.8.8",
    "8.8.4.4",
  ]

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

### Security Group Creation ###
resource "aws_security_group" "uipath_stack" {
  name        = "UiPath_Stack"
  description = "Security Group for UiPath_Stack"
  vpc_id      = aws_vpc.uipath.id

  tags = {
    Name = "${var.application}-${var.environment}"
  }

  # WinRM access from anywhere
  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = "true"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### INLINE - RDS DB MSSQL ###
resource "aws_db_subnet_group" "default" {
  name        = "${var.environment}-rds-mssql-subnet-group"
  description = "The ${var.environment} rds-mssql private subnet group."
  subnet_ids  = [aws_subnet.primary.id, aws_subnet.secondary.id]

  tags = {
    Name = "${var.application}-rds-mssql-subnet-group"
  }
}

resource "aws_db_instance" "default_mssql" {
  depends_on                = [aws_db_subnet_group.default]
  identifier                = var.db_name
  allocated_storage         = var.rds_allocated_storage
  license_model             = "license-included"
  storage_type              = "gp2"
  engine                    = "sqlserver-se"
  engine_version            = "14.00.3049.1.v1"
  instance_class            = var.rds_instance_class
  multi_az                  = var.rds_multi_az
  username                  = var.db_username
  password                  = var.db_password
  vpc_security_group_ids    = [aws_security_group.uipath_stack.id]
  db_subnet_group_name      = aws_db_subnet_group.default.id
  backup_retention_period   = 1
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = "${var.db_name}-mssql-final-snapshot"
}

### INLINE - W2016 STD UiPath Orchestrator ###
resource "aws_instance" "uipath_app_server" {
  depends_on = [
    aws_subnet.primary,
    aws_db_instance.default_mssql,
  ]
  ami           = data.aws_ami.server_ami.image_id
  instance_type = var.aws_app_instance_type
  key_name      = "${lookup(var.key_name, var.aws_region)}"
  user_data = "${data.template_file.init.rendered}"
  subnet_id = aws_subnet.primary.id
  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_type           = "gp2"
    volume_size           = 150
    delete_on_termination = true
  }

  # private_ip    = "10.100.101.2"

  vpc_security_group_ids = [
    aws_security_group.uipath_stack.id,
  ]

  tags = {
    Name = ${var.application}-${var.environment}"
  }
}

