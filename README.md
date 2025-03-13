# Terraform EC2 Metabase Module
A Terraform module for deploying a Metabase instance on AWS EC2 with database support.

## Overview

This module simplifies the deployment of Metabase on AWS, handling all necessary infrastructure components:

- EC2 instance with automated provisioning
- database integration (postgresql)
- Networking configuration (VPC, subnets, security groups)
- SSL certificate setup with Let's Encrypt (prebuild ami: [ami-0736dcb62aeed816a](https://www.aws.ioanyt.com/post/nginx-with-ssl-packaged-by-ioanyt-innovations-ubuntu22-04))
- DNS configuration with Route53

## Usage

### Basic Usage

```hcl
module "metabase_server" {
    source          = "github.com/oscarBack/terraform-ec2-metabase"
    vpc             = data.aws_vpc.default
    instance_type   = "t3a.small"
    igw_public_id   = aws_internet_gateway.example.id
    zone_domain     = data.aws_route53_zone.example
    project_name    = "metabase"
    db_username     = var.db_username
    db_password     = var.db_password
    email           = var.email
    db_host         = module.rds_instance.db_instance_endpoint
    metabase_domain = var.metabase_domain
}
```

### Complete Example with PostgreSQL RDS

See the [basic-postgres example](./examples/basic-postgres) for a complete example including:
- RDS PostgreSQL database setup
- VPC and subnet configuration
- Security group configuration
- DNS record creation

## Architecture

This module deploys the following components:

1. **EC2 Instance**: Runs the Metabase application in Docker
2. **Security Groups**: Controls traffic to/from the EC2 instance
3. **Elastic IP**: Provides a static public IP address
4. **Route53 Records**: Maps your domain to the Metabase instance
5. **Network Infrastructure**: Creates necessary subnets and routing

The EC2 instance is provisioned with scripts that:
- Install Docker and Docker Compose
- Pull and run the Metabase container
- Configure Nginx as a reverse proxy
- Set up SSL certificates using Let's Encrypt

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc | The VPC object | `object` | n/a | yes |
| instance_type | EC2 instance type | `string` | `"t3a.small"` | no |
| igw_public_id | Internet Gateway ID | `string` | n/a | yes |
| zone_domain | Route53 zone domain object | `object` | n/a | yes |
| project_name | Name of the project | `string` | n/a | yes |
| db_username | Database username | `string` | n/a | yes |
| db_password | Database password | `string` | n/a | yes |
| email | Email address for SSL notifications | `string` | n/a | yes |
| db_host | Database host endpoint | `string` | n/a | yes |
| metabase_domain | Domain for Metabase | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| ubuntu_instance_public_ip | Public IP address of the EC2 instance |
| sg_id | Security group ID |

## License

MIT Licensed. See [LICENSE](./LICENSE) for full details.

## Contributing

Contributions are welcome! Feel free to submit pull requests with:

- Bug fixes
- New features
- Additional examples
- Test cases
- Documentation improvements

### Cost Considerations

This project is designed to maintain a low-cost infrastructure footprint (currently approximately 30 USD/month). When contributing:

- Prioritize cost-effective solutions
- Document cost implications of new features
- Consider providing cost-optimization options
- Test changes to ensure they don't significantly increase infrastructure costs

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

For major changes, please open an issue first to discuss what you would like to change.

---

## Questions for Documentation Improvement

To help me improve this documentation:

1. What is your primary use case for deploying Metabase on AWS?
2. Do you need additional examples for other database types (MySQL, etc.)?
3. Would you like to see examples for deployment in private subnets?
4. Are there specific security features you'd like to see included or documented?
5. Do you need guidance on backup strategies for your Metabase installation?
6. Would you like to see integration examples with other AWS services (like S3, CloudFront)?
7. Would step-by-step deployment instructions be helpful for your team?
8. Are there any customization options you'd like to see added to the module?

I'd be happy to get your issues on GitHub issues.