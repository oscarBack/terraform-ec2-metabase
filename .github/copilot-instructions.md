# Copilot Instructions - Terraform EC2 Metabase Module

## Project Overview
This is a **cost-optimized** Terraform module (~$30/month) that deploys Metabase on AWS EC2 with PostgreSQL RDS integration. The module uses a pre-built AMI (`ami-0736dcb62aeed816a`) with Nginx and SSL tooling.

## Architecture Pattern
- **Single EC2 instance** running Metabase in Docker container
- **CloudInit multi-part user data** for automated provisioning via shell scripts
- **Nginx reverse proxy** with automatic Let's Encrypt SSL certificates
- **RDS PostgreSQL** backend with private subnet isolation
- **Route53 DNS** integration with domain management

## Key File Structure
```
main.tf              # Core infrastructure (EC2, networking, security groups)
variables.tf         # Module inputs (no defaults for secrets)
outputs.tf           # Public IP and security group ID
install_docker.sh    # Docker setup + Metabase container deployment
activate_ssl.sh      # Let's Encrypt certificate provisioning
redirect_to_metabase.sh # Nginx proxy configuration
examples/basic-postgres/ # Complete deployment example with RDS
```

## Critical Development Patterns

### CloudInit Template Usage
All shell scripts use `templatefile()` with variable interpolation:
```hcl
content = templatefile("${path.module}/install_docker.sh", {
  db_username = var.db_username
  db_password = var.db_password
  db_host     = var.db_host
})
```

### Shell Script Conventions
- **Comprehensive logging** to `/var/log/[script_name].log`
- **Retry mechanisms** with `retry_command()` function for network operations
- **Apt lock handling** with `wait_for_apt()` to prevent race conditions
- **Error handling** with `execute()` function that logs and exits on failure

### Security Group Pattern
Uses new AWS VPC security group rules (not legacy inline rules):
```hcl
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web_sg.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
```

### Database Connection Pattern
PostgreSQL connections use JDBC URI format in environment variables:
```bash
jdbc:postgresql://${db_username}:${db_password}@${db_host}/metabase
```

## Cost Optimization Focus
- Default to `t3a.small` instances (cost-effective AMD processors)
- Single AZ deployment for RDS (no multi-AZ unless explicitly needed)
- `db.t4g.micro` for RDS (ARM-based cost savings)
- Fixed allocation storage with reasonable max limits

## Development Workflow
1. Test changes with `examples/basic-postgres/` - it's the canonical usage pattern
2. Validate shell scripts handle apt locks and network timeouts
3. Check CloudInit logs on EC2 instance: `/var/log/cloud-init-output.log`
4. Verify service logs: `/var/log/install_docker.log`, `/var/log/activate_ssl.log`

## Integration Dependencies
- **Route53 hosted zone** must exist for domain
- **VPC with internet gateway** required for public subnet creation
- **RDS subnet group** needs private subnets in different AZs
- **Security group dependencies** - RDS SG must reference EC2 SG

## Variable Naming Convention
- Use descriptive names without type suffixes (`zone_domain` not `zone_domain_object`)
- Database credentials prefixed with `db_` (`db_username`, `db_password`, `db_host`)
- Infrastructure IDs suffixed with type (`igw_public_id`)
