### Establish Provider and Access ###

provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

### VPC Creation ###
resource "aws_vpc" "uirobot" {
  cidr_block           = "10.100.101.0/24"
  enable_dns_hostnames = "true"

  tags {
    Name = "${var.stack_name}"
  }
}

### Create Subnet for all of our resources ###
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.uirobot.id}"
  cidr_block              = "10.100.101.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.stack_name}"
  }
}

### IGW for external calls ###
resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.uirobot.id}"

  tags {
    Name = "${var.stack_name}"
  }
}

### Route Table ###
resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.uirobot.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }
}

### Main Route Table ###
resource "aws_main_route_table_association" "main" {
  vpc_id         = "${aws_vpc.uirobot.id}"
  route_table_id = "${aws_route_table.main.id}"
}

### Provide a VPC DHCP Option Association ###
resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${aws_vpc.uirobot.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.dns_resolver.id}"
}

### Set DNS resolvers so we can join a Domain Controller ###
resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = [
    "8.8.8.8",
    "8.8.4.4",
  ]

  tags {
    Name = "${var.stack_name}"
  }
}

### Security Group Creation ###
resource "aws_security_group" "uirobot_stack" {
  name        = "UiRobot_Stack"
  description = "Security Group for UiRobot_Stack"
  vpc_id      = "${aws_vpc.uirobot.id}"

  tags = {
    Name = "${var.stack_name}"
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

}

### INLINE - Bootstrap Windows Server 2016 ###
data "template_file" "init" {
  template = <<EOF
    <script>
      winrm quickconfig -q & winrm set winrm/config/winrs @{MaxMemoryPerShellMB="300"} & winrm set winrm/config @{MaxTimeoutms="1800000"} & winrm set winrm/config/service @{AllowUnencrypted="true"} & winrm set winrm/config/service/auth @{Basic="true"} & winrm/config @{MaxEnvelopeSizekb="8000kb"}
    </script>
    <powershell>
    netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
    $admin = [ADSI]("WinNT://./administrator, user")
    $admin.SetPassword("${var.admin_password}")
    </powershell>
EOF

  vars {
    admin_password = "${var.admin_password}"
  }
}

### INLINE - W2016 STD UiPath Robot ###
resource "aws_instance" "uirobot_app_server" {
  ami           = "${lookup(var.aws_w2016_std_amis, var.aws_region)}"
  instance_type = "${var.aws_app_instance_type}"
  key_name      = "${lookup(var.key_name, var.aws_region)}"
  user_data     = "${data.template_file.init.rendered}"
  subnet_id     = "${aws_subnet.default.id}"
  count         = "${var.instance_count}"

  # private_ip    = "10.100.101.2"

  vpc_security_group_ids = [
    "${aws_security_group.uirobot_stack.id}",
  ]

  tags = {
    Name = "${var.app_name}-${count.index}"
  }

  ### Copy Scripts to EC2 instance ###
  provisioner "file" {
    source      = "${path.module}/scripts/"
    destination = "C:\\scripts"

    connection = {
      type     = "winrm"
      user     = "administrator"
      password = "${var.admin_password}"
      agent    = "false"
    }
  }
}

resource "null_resource" "terraform_robot" {
  count = "${var.instance_count}"

  connection {
    type     = "winrm"
    host     = "${element(aws_instance.uirobot_app_server.*.public_ip, count.index)}"
    user     = "administrator"
    password = "${var.admin_password}"
    agent    = false

    # https    = false
    # insecure = true
    # timeout  = "3m"
  }

  provisioner "remote-exec" {
    inline = [
      "powershell.exe Set-ExecutionPolicy Unrestricted -force",
      "powershell.exe -ExecutionPolicy Bypass -File \"C:\\scripts\\Install-UiRobot.ps1\" -orchestratorUrl \"${var.orchestrator_url}\" -Tennant \"${var.orchestrator_tennant}\" -orchAdmin \"${var.orchestrator_admin}\" -orchPassword \"${var.orchestrator_adminpw}\" -adminUsername \"${var.vm_username}\" -machinePassword \"${var.vm_password}\" -HostingType \"${var.hosting_type}\" -RobotType \"${var.robot_type}\" -credType \"${var.cred_type}\" ",
      "powershell.exe Remove-Item -LiteralPath \"C:\\scripts\" -Force -Recurse",
      "shutdown /r /f /t 5 /c \"forced reboot\"",
    ]
  }
}
