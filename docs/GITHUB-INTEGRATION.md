# GitHub Integration Guide

This guide covers GitHub Actions workflows, repository deployment features, and CI/CD integration for the HomeLab project.

## Overview

The HomeLab project includes several GitHub integrations:

- **Automated Testing**: Run tests on pull requests and pushes
- **Code Quality Checks**: PowerShell analysis, markdown linting, YAML validation
- **Repository Deployment**: Deploy GitHub repositories to Azure
- **Security Scanning**: Vulnerability scanning and dependency checks
- **Documentation**: Automated documentation updates

## GitHub Actions Workflows

### Core Workflows

#### 1. HomeLab Tests (`run-tests.yml`)
**Trigger**: Push to main, pull requests, manual dispatch
**Purpose**: Run comprehensive test suite

```yaml
# Manual trigger with test type selection
workflow_dispatch:
  inputs:
    test_type:
      description: "Type of tests to run"
      type: choice
      options: [All, Unit, Integration, Workflow]
```

**Features**:
- Installs required PowerShell modules
- Runs Pester tests with HTML report generation
- Uploads test results as artifacts
- Supports different test types

#### 2. Code Quality (`code-quality.yml`)
**Trigger**: Push to main/develop, pull requests
**Purpose**: Ensure code quality and standards

**Checks**:
- PowerShell script analysis (PSScriptAnalyzer)
- Markdown linting (markdownlint)
- YAML validation (yamllint)
- Security scanning (Trivy)
- Dependency auditing (npm/pnpm audit)
- File structure validation

#### 3. Test with PR Comments (`test-with-comments.yml`)
**Trigger**: Pull requests to main
**Purpose**: Run tests and comment results on PRs

**Features**:
- Runs unit and integration tests
- Posts success/failure comments on PRs
- Provides detailed test feedback
- Includes next steps for failures

### Repository Deployment Workflows

#### 1. Deploy to Azure (`deploy-azure.yml`)
**Trigger**: Manual dispatch, reusable workflow
**Purpose**: Deploy applications to Azure with custom domains

**Inputs**:
- `deployment_type`: static, appservice, auto
- `environment`: dev, staging, prod
- `subdomain`: Custom subdomain
- `custom_domain`: Domain name
- `azure_location`: Azure region

**Features**:
- Auto-detects deployment type from project files
- Supports multiple environments
- Custom domain configuration
- SSL certificate automation
- Deployment status reporting

#### 2. Multi-Environment Deploy (`deploy-multi-env.yml`)
**Trigger**: Manual dispatch
**Purpose**: Deploy to multiple environments simultaneously

**Example Usage**:
```yaml
environments: "dev,staging,prod"
base_subdomain: "myapp"
# Results in: myapp-dev, myapp-staging, myapp
```

## Repository Deployment Feature

### GitHub Repository Deployment

The HomeLab system can deploy GitHub repositories directly to Azure using the `Deploy-GitHubRepository` function.

### Supported Deployment Types

#### Auto-Detection Logic
```powershell
# Static Web App indicators
- index.html files
- React/Vue/Angular dependencies
- Build output directories

# App Service indicators  
- Express/Node.js server frameworks
- Python WSGI/ASGI applications
- .NET applications

# Container App indicators
- Dockerfile present
- Docker Compose files

# Infrastructure indicators
- Bicep files (*.bicep)
- ARM templates
```

### Usage Examples

#### Deploy React Application
```powershell
Deploy-GitHubRepository -Repository "user/react-app" -DeploymentType static -CustomDomain "example.com" -Subdomain "app"
```

#### Deploy Node.js API
```powershell
Deploy-GitHubRepository -Repository "user/api-server" -DeploymentType appservice -Environment prod
```

#### Auto-Detect Deployment
```powershell
Deploy-GitHubRepository -Repository "user/my-project" -DeploymentType auto
```

## Authentication Setup

### GitHub-to-Azure OIDC (Recommended)

#### 1. Create Service Principal
```bash
az ad sp create-for-rbac \
  --name "github-actions-deployment" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{rg-name}
```

#### 2. Configure Federated Credentials
```bash
az ad app federated-credential create \
  --id {client-id} \
  --parameters '{
    "name":"github-actions",
    "issuer":"https://token.actions.githubusercontent.com",
    "subject":"repo:{owner}/{repo}:ref:refs/heads/main",
    "audiences":["api://AzureADTokenExchange"]
  }'
```

#### 3. GitHub Secrets (OIDC)
```
AZURE_SUBSCRIPTION_ID    # Azure subscription ID
AZURE_CLIENT_ID          # Service principal client ID
AZURE_TENANT_ID          # Azure tenant ID
GITHUB_TOKEN             # GitHub personal access token
```

### Legacy Authentication (Not Recommended)
```
AZURE_CLIENT_SECRET      # Service principal secret
AZURE_CREDENTIALS        # Complete credentials JSON
```

## Workflow Configuration

### Environment-Specific Settings

#### Development
```yaml
environment: dev
azure_location: eastus
subdomain_suffix: "-dev"
sku: Free
```

#### Staging
```yaml
environment: staging
azure_location: eastus
subdomain_suffix: "-staging"
sku: Basic
```

#### Production
```yaml
environment: prod
azure_location: eastus
subdomain_suffix: ""
sku: Standard
```

### Custom Domain Setup

#### DNS Configuration
After deployment, configure DNS records:

**Static Web Apps**:
```
Type: CNAME
Name: {subdomain}
Value: {app-name}.azurestaticapps.net
```

**App Service**:
```
Type: CNAME
Name: {subdomain}
Value: {app-name}.azurewebsites.net
```

**Domain Verification**:
```
Type: TXT
Name: asuid.{subdomain}
Value: {verification-id}
```

## Security Best Practices

### Secret Management
- Use OIDC federation instead of long-lived secrets
- Scope service principals to specific resource groups
- Rotate secrets regularly
- Use environment-specific service principals

### Workflow Security
- **Pin action versions to specific commits or exact versions** (not moving tags like @v4)
- Use `permissions` blocks to limit token scope
- Validate inputs in reusable workflows
- Enable branch protection rules
- Regularly audit and update pinned action versions

### Example Secure Workflow
```yaml
permissions:
  contents: read
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4.1.2  # Pin to specific version
      - uses: azure/login@v1.4.6       # Pin to specific version
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Finding Specific Action Versions

To find specific commit SHAs or version numbers for pinning:

1. **Using GitHub Releases**: Visit the action's repository releases page
   ```
   https://github.com/actions/checkout/releases
   https://github.com/Azure/login/releases
   ```

2. **Using Commit SHA**: For maximum security, pin to specific commits
   ```yaml
   - uses: actions/checkout@8ade135a41bc03ea155e62e844d188df1ea18608  # v4.1.2
   - uses: azure/login@92a5484dfaf04ca78a94597f4f19fea633851fa2     # v1.4.6
   ```

3. **Automated Updates**: Use Dependabot to keep pinned versions updated
   ```yaml
   # .github/dependabot.yml
   version: 2
   updates:
     - package-ecosystem: "github-actions"
       directory: "/"
       schedule:
         interval: "weekly"
   ```

## Monitoring and Troubleshooting

### Workflow Monitoring
- Check Actions tab for workflow runs
- Review job logs for detailed output
- Monitor deployment status in Azure Portal
- Set up alerts for failed deployments

### Common Issues

#### Authentication Failures
```
Error: AADSTS70021: No matching federated identity record found
```
**Solution**: Verify federated credential configuration

#### Deployment Timeouts
```
Error: The operation was canceled
```
**Solution**: Increase timeout values or check Azure service status

#### DNS Propagation Issues
```
Error: Domain verification failed
```
**Solution**: Wait for DNS propagation (up to 48 hours)

### Debug Mode
Enable debug logging in workflows:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

## Customization

### Adding New Deployment Types

1. Update auto-detection logic in `Get-AutoDetectedDeploymentType`
2. Add deployment function (e.g., `Invoke-CustomDeployment`)
3. Update workflow validation
4. Add tests for new deployment type

### Custom Workflow Templates

Create `.github/workflows/custom-deploy.yml`:
```yaml
name: Custom Deployment
on:
  workflow_dispatch:
    inputs:
      custom_param:
        description: 'Custom parameter'
        required: true

jobs:
  deploy:
    uses: ./.github/workflows/deploy-azure.yml
    with:
      deployment_type: ${{ inputs.custom_param }}
    secrets: inherit
```

## Performance Optimization

### Workflow Performance
- Cache dependencies between runs
- Use matrix builds for parallel execution
- Optimize Docker builds with multi-stage builds
- Use artifact caching for build outputs

### Deployment Performance
- Use deployment slots for zero-downtime deployments
- Implement health checks
- Use CDN for static content
- Enable compression and caching

## Integration Examples

### Continuous Deployment
```yaml
on:
  push:
    branches: [main]
    paths: ['src/**']

jobs:
  deploy:
    if: github.ref == 'refs/heads/main'
    uses: ./.github/workflows/deploy-azure.yml
    with:
      deployment_type: auto
      environment: prod
```

### Feature Branch Deployments
```yaml
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  deploy-preview:
    uses: ./.github/workflows/deploy-azure.yml
    with:
      deployment_type: static
      environment: dev
      subdomain: "pr-${{ github.event.number }}"
```

## Related Documentation

- [Website Deployment Guide](WEBSITE-DEPLOYMENT.md)
- [Testing Guide](TESTING.md)
- [Development Guide](DEVELOPMENT.md)
- [Security Checklist](SECURITY-CHECKLIST.md)

## Support

For GitHub integration issues:
1. Check workflow logs in Actions tab
2. Verify authentication setup
3. Review this documentation
4. Open an issue in the repository