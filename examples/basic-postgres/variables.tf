variable "region" {
    description = "The AWS region to deploy to"
    default     = "us-east-1"
}

variable "environment" {
    description = "The environment to deploy to"
}

variable "vpc_id" {
    description = "The VPC ID to deploy to"
}

variable "igw_public_id" {}
variable "subnet_id" {}
variable "project_name" {
    description = "The name of the project"
    default     = "metabase5"
}

variable "db_username" {
    description = "The username for the database"
}

variable "db_password" {
    description = "The password for the database"
}

variable "email" {
  description = "Email"
  type        = string
}

variable "metabase_domain" {
  description = "Metabase domain"
  type        = string
}

variable "root_domain" {
    description = "The root domain to use for the project, ex: example.com."
    type = string
}