
terraform {
  cloud {
    organization = "example"

    workspaces {
      name = "metabase"
    }
  }
  # Terraform working directory: examples/basic-postgres

}

provider "aws" {
  region = var.region

  default_tags {
    tags = {}
  }
}


locals {
  rds_subnets = {
    a = {
      az         = "us-east-1a"
      cidr_index = 0
    }
    b = {
      az         = "us-east-1b"
      cidr_index = 1
    }
  }
}



#############################
# Networking Configuration  #
#############################

# create domain
data "aws_route53_zone" "selected" {
  name         = var.root_domain
  private_zone = false
}

data "aws_vpc" "default" {
  id = var.vpc_id
}

variable "subnet_cidr_block" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = "172.31.96.0/20"
}

resource "aws_subnet" "rds_private" {
  for_each = local.rds_subnets

  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.subnet_cidr_block, 4, each.value.cidr_index)
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-rds-private-subnet-${each.key}"
    Description = "Private subnet for RDS in AZ ${each.key}"
    Purpose     = "RDS Database"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg-metabase"
  description = "Allow inbound traffic from specified security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.metabase_server.sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_sg-metabase"
  }
}



################################
#           Database           #
################################

module "rds_instance" {
  source                      = "terraform-aws-modules/rds/aws"
  version                     = "6.10.0"
  identifier                  = "metabase"
  engine                      = "postgres"
  engine_version              = "16.3"
  instance_class              = "db.t4g.micro"
  allocated_storage           = 20
  max_allocated_storage       = 40
  db_name                     = "metabase"
  username                    = var.db_username
  password                    = var.db_password
  manage_master_user_password = false
  port                        = 5432
  multi_az                    = false
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]
  publicly_accessible         = false

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = values(aws_subnet.rds_private)[*].id

  backup_retention_period  = 7
  skip_final_snapshot      = false
  deletion_protection      = true
  delete_automated_backups = false

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # DB parameter group
  family = "postgres16"

  tags = {
    Name = "rds-metabase"
  }
}


################################
#            Server            #
################################

module "metabase_server" {
  source          = "../../"
  vpc             = data.aws_vpc.default
  instance_type   = "t3a.small"
  igw_public_id   = var.igw_public_id
  zone_domain     = data.aws_route53_zone.selected
  project_name    = var.project_name
  db_username     = var.db_username
  db_password     = var.db_password
  email           = var.email
  db_host         = module.rds_instance.db_instance_endpoint
  metabase_domain = var.metabase_domain
}