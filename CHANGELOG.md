# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-28

### Added
- Initial release of Azure HomeLab Setup
- Complete PowerShell module for Azure infrastructure management
- Modular architecture with 7 specialized modules:
  - HomeLab.Core: Foundation module with configuration and logging
  - HomeLab.Azure: Azure resource deployment and management
  - HomeLab.Security: VPN and certificate management
  - HomeLab.UI: User interface components and menus
  - HomeLab.Monitoring: Resource monitoring and alerting
  - HomeLab.Web: Website deployment and hosting
  - HomeLab.DNS: DNS zone and record management
- Interactive menu system for easy management
- Comprehensive test suite with unit, integration, and workflow tests
- GitHub Actions workflows for CI/CD
- Extensive documentation with diagrams and guides

### Infrastructure Features
- Azure Virtual Network with multiple subnets
- Point-to-Site VPN Gateway with certificate authentication
- NAT Gateway for outbound internet connectivity
- Network Security Groups for traffic control
- Cost optimization features (enable/disable NAT Gateway)

### VPN Management
- Root and client certificate generation
- VPN Gateway configuration and management
- Client VPN setup and connection management
- Certificate lifecycle management

### Website Deployment
- Static website deployment to Azure Static Web Apps
- Dynamic website deployment to Azure App Service
- Custom domain configuration
- SSL certificate management
- Multi-environment deployment support

### DNS Management
- Azure DNS zone creation and management
- DNS record management (A, CNAME, MX, TXT, etc.)
- Domain delegation configuration
- DNS propagation monitoring

### Monitoring & Alerting
- Azure resource health monitoring
- Cost tracking and analysis
- Performance metrics collection
- Custom alerting rules

### Documentation
- Comprehensive README with setup instructions
- Architecture diagrams and network layouts
- Step-by-step deployment guides
- Troubleshooting documentation
- API reference for all modules

### Testing
- Unit tests for all modules
- Integration tests for cross-module functionality
- Workflow tests for end-to-end scenarios
- Automated testing via GitHub Actions
- Mock implementations for testing without Azure resources

### Security
- Secure certificate management
- Azure authentication integration
- Network security best practices
- Secure storage of configuration data

### Fixed
- PowerShell syntax errors in DNS module
- Resource name generation in workflow tests
- Module import issues in test suite
- Missing dependencies for YAML processing

### Security
- All Azure credentials are managed through secure methods
- Certificate private keys are properly protected
- Network traffic is secured through NSGs and VPN

## [Unreleased]

### Planned
- Azure Key Vault integration for secret management
- Terraform deployment option
- Azure DevOps pipeline templates
- Container deployment support
- Advanced monitoring dashboards
- Multi-region deployment support
