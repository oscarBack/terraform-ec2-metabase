variable "vpc" {
  description = "The VPC object"
  type = object({
    id         = string
    cidr_block = string
  })
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
  type = object({
    name    = string
    zone_id = string
  })
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to reach SSH (port 22). Example: 203.0.113.10/32"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.ssh_ingress_cidr))
    error_message = "ssh_ingress_cidr must be a valid CIDR range such as 203.0.113.10/32."
  }
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
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

variable "metabase_version" {
  description = "Metabase Docker image tag"
  type        = string
  default     = "v0.52.6.x"

  validation {
    condition     = can(regex("^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$", var.metabase_version))
    error_message = "metabase_version must be a valid Docker image tag."
  }
}