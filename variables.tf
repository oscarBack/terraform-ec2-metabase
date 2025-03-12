variable "vpc" {
  description = "The VPC object"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3a.small"
}

variable "igw_public_id" {
  description = "Internet Gateway ID"
  type        = string
}

variable "zone_domain" {
  description = "Route53 zone domain object"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
}

variable "email" {
  description = "Email address"
  type        = string
}

variable "db_host" {
  description = "Database host endpoint"
  type        = string
}

variable "metabase_domain" {
  description = "Domain for Metabase"
  type        = string
}