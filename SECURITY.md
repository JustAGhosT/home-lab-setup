# Security Policy

## Supported Versions

We actively support the following versions of Azure HomeLab Setup with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability in Azure HomeLab Setup, please report it responsibly.

### How to Report

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Send an email to the project maintainer with details about the vulnerability
3. Include as much information as possible:
   - Description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact
   - Suggested fix (if you have one)

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your vulnerability report within 48 hours
- **Initial Assessment**: We will provide an initial assessment within 5 business days
- **Updates**: We will keep you informed of our progress throughout the investigation
- **Resolution**: We aim to resolve critical vulnerabilities within 30 days

### Responsible Disclosure

We follow responsible disclosure practices:

- We will work with you to understand and resolve the issue
- We will not take legal action against researchers who report vulnerabilities responsibly
- We will credit you for the discovery (unless you prefer to remain anonymous)
- We will coordinate the disclosure timeline with you

## Security Best Practices

When using Azure HomeLab Setup, please follow these security best practices:

### Azure Credentials
- Never commit Azure credentials to version control
- Use Azure service principals with minimal required permissions
- Rotate credentials regularly
- Use Azure Key Vault for storing sensitive information

### Certificates
- Protect certificate private keys
- Use strong passwords for certificate stores
- Regularly rotate VPN certificates
- Store certificates securely and limit access

### Network Security
- Configure Network Security Groups (NSGs) appropriately
- Use VPN for secure remote access
- Regularly review and audit network access rules
- Monitor network traffic for suspicious activity

### Configuration Management
- Keep configuration files secure and don't commit sensitive data
- Use environment variables for sensitive configuration
- Regularly review and update security configurations
- Implement proper access controls

### PowerShell Security
- Run PowerShell with appropriate execution policies
- Validate all input parameters
- Use secure string handling for sensitive data
- Keep PowerShell modules updated

## Security Features

Azure HomeLab Setup includes several security features:

### Built-in Security
- Certificate-based VPN authentication
- Network Security Groups for traffic control
- Secure credential handling
- Input validation and sanitization
- Error handling that doesn't expose sensitive information

### Monitoring and Alerting
- Resource monitoring capabilities
- Cost tracking to detect unusual activity
- Health checks for infrastructure components
- Logging of important operations

### Access Control
- Role-based access through Azure RBAC
- Principle of least privilege implementation
- Secure certificate management
- Protected configuration storage

## Known Security Considerations

### Azure Costs
- Monitor Azure costs to detect unauthorized resource creation
- Set up billing alerts and spending limits
- Regularly review deployed resources

### VPN Security
- VPN certificates have expiration dates - monitor and renew
- Client certificates should be properly distributed and managed
- VPN access should be limited to authorized users only

### PowerShell Execution
- The module requires elevated permissions for some operations
- Always run from trusted sources
- Review scripts before execution in production environments

## Updates and Patches

- Security updates will be released as patch versions (e.g., 1.0.1)
- Critical security fixes will be backported to supported versions
- Subscribe to repository notifications to stay informed of security updates
- Test security updates in non-production environments first

## Compliance

This project aims to follow security best practices including:

- Secure coding practices
- Input validation and sanitization
- Proper error handling
- Secure credential management
- Regular security reviews

## Contact

For security-related questions or concerns that are not vulnerabilities, you can:

1. Create a GitHub issue with the "security" label
2. Start a discussion in the repository
3. Contact the maintainers directly

Thank you for helping keep Azure HomeLab Setup secure!
