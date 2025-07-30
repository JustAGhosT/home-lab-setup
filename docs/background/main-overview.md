# main-overview

## Development Guidelines

- Only modify code directly relevant to the specific request. Avoid changing unrelated functionality.
- Never replace code with placeholders like `# ... rest of the processing ...`. Always include complete code.
- Break problems into smaller steps. Think through each step separately before implementing.
- Always provide a complete PLAN with REASONING based on evidence from code and logs before making changes.
- Explain your OBSERVATIONS clearly, then provide REASONING to identify the exact issue. Add console logs when needed to gather more information.

## Core HomeLab Components

### Azure Infrastructure Management (Importance: 95)
- Modular PowerShell modules for Azure resource deployment and management
- VPN Gateway setup with Point-to-Site connectivity and certificate management
- NAT Gateway configuration for outbound internet access with cost optimization
- Network security groups and subnet management for secure networking

Key paths:
- HomeLab/modules/HomeLab.Azure/
- HomeLab/modules/HomeLab.Security/
- HomeLab/modules/HomeLab.Core/

### VPN and Security Management (Importance: 90)
- Certificate creation and management for VPN authentication
- Client certificate generation and distribution
- VPN connection management and status monitoring
- Secure remote access configuration

Key paths:
- HomeLab/modules/HomeLab.Security/Public/
- docs/security/client-certificate-management.md
- docs/networking/vpn-gateway.md

### Website and DNS Management (Importance: 85)
- Azure App Service and Static Web App deployment
- Custom domain configuration and SSL certificate management
- DNS zone management and record configuration
- Continuous deployment setup

Key paths:
- HomeLab/modules/HomeLab.Web/
- HomeLab/modules/HomeLab.DNS/
- docs/WEBSITE-DEPLOYMENT.md

### Testing and Quality Assurance (Importance: 80)
- Comprehensive PowerShell testing framework using Pester
- Unit, integration, and workflow testing capabilities
- Code coverage analysis and HTML report generation
- Automated test execution in GitHub Actions

Key paths:
- tests/Run-HomeLab-Tests.ps1
- tests/unit/
- tests/integration/
- .github/workflows/run-tests.yml

### Monitoring and Cost Management (Importance: 75)
- Azure resource monitoring and health checks
- Cost tracking and optimization strategies
- Background job monitoring for long-running deployments
- Resource usage analysis and alerting

Key paths:
- HomeLab/modules/HomeLab.Monitoring/
- docs/diagrams/cost-optimization-strategy.md

### Configuration and Setup Management (Importance: 70)
- Environment-specific configuration management
- Interactive setup and deployment menus
- Resource naming conventions and validation
- Logging and troubleshooting utilities

Key paths:
- HomeLab/modules/HomeLab.UI/
- HomeLab.psd1
- docs/SETUP.md

$END$