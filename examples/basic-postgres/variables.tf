variable "region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "The VPC ID to deploy to"
  type        = string
}

variable "igw_public_id" {
  type = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to reach SSH (port 22). Example: 203.0.113.10/32"
  type        = string
}

variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
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
  type        = string
}