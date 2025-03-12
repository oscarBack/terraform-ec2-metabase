resource "aws_security_group" "web_sg" {
  name        = "web_sg-${var.project_name}"
  description = "Allow inbound traffic on ports 80 and 443"
  vpc_id      = var.vpc.id

  lifecycle { 
    create_before_destroy = true 
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web_sg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web_sg.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

data "cloudinit_config" "server_config" {
  gzip          = true
  base64_encode = true

  # activate ssl
  part {
    filename     = "activate_ssl.sh"
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/activate_ssl.sh", {
      metabase_domain = var.metabase_domain
      email           = var.email
    })
  }

  # install docker with environment variables
  part {
    filename     = "install_docker.sh"
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/install_docker.sh", {
      db_username = var.db_username
      db_password = var.db_password
      db_host     = var.db_host
    })
  }

  # install psql
  part {
    filename     = "install_psql.sh"
    content_type = "text/x-shellscript"
    content      = file("${path.module}/install_psql.sh")
  }

  # redirect nginx port to Metabase port
  part {
    filename     = "redirect_to_metabase.sh"
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/redirect_to_metabase.sh", {
      metabase_domain = var.metabase_domain
    })
  }
}

resource "aws_instance" "web_server" {
  ami                         = "ami-0736dcb62aeed816a"
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true

  user_data                   = data.cloudinit_config.server_config.rendered
  user_data_replace_on_change = true

  depends_on = [
    var.igw_public_id
  ]

  tags = {
    Name = "ssl-web-server-${var.project_name}"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = var.vpc.id
  cidr_block              = cidrsubnet(var.vpc.cidr_block, 4, 10) #cidr_block = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-public-${var.project_name}"
  }
}

resource "aws_route53_record" "server" {
  zone_id = var.zone_domain.zone_id
  name    = "${var.project_name}.${var.zone_domain.name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.lb.public_ip]
}

resource "aws_eip" "lb" {
  instance = aws_instance.web_server.id

  tags = {
    Name = "web-server-${var.project_name}"
  }
}