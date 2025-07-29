# Changelog

All notable changes to the HomeLab project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive testing framework with Pester 5.0+
- GitHub Actions workflows for CI/CD
- GitHub repository deployment functionality
- OIDC federation support for secure authentication
- Automated code quality checks (PowerShell, Markdown, YAML)
- Security scanning with Trivy
- Dependency auditing for npm/pnpm packages
- HTML test report generation with PScribo fallback
- API reference documentation
- Development and contribution guidelines
- Comprehensive troubleshooting guide

### Changed
- Updated README.md to reflect actual project structure
- Enhanced security checklist with modern threats and GitHub integration
- Improved error handling in PowerShell modules
- Updated cost estimates with current Azure pricing

### Fixed
- ReDoS vulnerability in markdown linter regex patterns
- PowerShell syntax errors in test runner
- Path validation issues in GitHub deployment
- HTML comment tracking in markdown linter
- File-level vs line-level fix application in linter

### Security
- Implemented bounded regex quantifiers to prevent ReDoS attacks
- Added secure path validation to prevent directory traversal
- Enhanced secret management practices
- Improved supply chain security measures

## [1.0.0] - 2024-01-XX

### Initial Release
- Initial HomeLab PowerShell module structure
- Azure Virtual Network deployment
- VPN Gateway configuration and management
- Certificate management for VPN authentication
- NAT Gateway deployment and cost management
- Website deployment to Azure App Service and Static Web Apps
- DNS zone management with Azure DNS
- Interactive menu system for easy management
- Configuration management system
- Logging and monitoring capabilities
- Cost tracking and optimization features

For the complete changelog, see [docs/CHANGELOG.md](docs/CHANGELOG.md).