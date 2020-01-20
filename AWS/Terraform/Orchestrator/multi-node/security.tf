### Security Group Creation ###
resource "aws_security_group" "uipath_stack" {
  name        = "${var.application}-${var.environment}"
  description = "Security Group for ${var.application}"
  vpc_id      = "${aws_vpc.uipath.id}"

  tags = {
    Name = "${var.application}"
    Tier = "UiPathStack"
  }

  # WinRM access from anywhere
  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  ingress {
    from_port   = 10000
    to_port     = 10000
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  ingress {
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  egress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  egress {
    from_port   = 10000
    to_port     = 10000
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }
  egress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }
  egress {
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }


  egress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

  ### FileGateway security rules ###
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
    self        = "true"
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "udp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
    self        = "true"
  }

  ingress {
    from_port   = 111
    to_port     = 111
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
    self        = "true"
  }

  ingress {
    from_port   = 111
    to_port     = 111
    protocol    = "udp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
    self        = "true"
  }

  ingress {
    from_port   = 20048
    to_port     = 20048
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
    self        = "true"
  }

  ingress {
    from_port   = 20048
    to_port     = 20048
    protocol    = "udp"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
    self        = "true"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
    self        = "true"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr_block}", "${var.security_cidr_block}"]
  }

}
