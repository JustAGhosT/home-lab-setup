# HomeLab.GitHub Module

The HomeLab.GitHub module provides comprehensive GitHub integration for the HomeLab deployment system. It enables you to authenticate with GitHub, browse your repositories, select repositories for deployment, and seamlessly deploy them to your Azure infrastructure.

## Features

- 🔐 **Secure Authentication** - Uses GitHub Personal Access Tokens stored securely in Windows Credential Manager
- 📋 **Repository Management** - Browse, filter, and select from your GitHub repositories
- 🚀 **Integrated Deployment** - Deploy selected repositories directly to Azure infrastructure
- 🔄 **Repository Cloning** - Clone repositories locally for development or deployment
- ⚙️ **Configuration Management** - Persistent settings and selected repository storage
- 🌐 **Cross-Platform Support** - Works on Windows, Linux, and macOS

## Quick Start

### 1. Connect to GitHub

```powershell
# Import the module
Import-Module HomeLab.GitHub

# Connect to GitHub (you'll be prompted for your Personal Access Token)
Connect-GitHub

# Test the connection
Test-GitHubConnection
```

### 2. Browse and Select a Repository

```powershell
# List all your repositories
Get-GitHubRepositories

# Filter repositories
Get-GitHubRepositories -Type private -Language PowerShell

# Interactive repository selection
Select-GitHubRepository
```

### 3. Deploy a Repository

```powershell
# Deploy the selected repository
Deploy-GitHubRepository

# Deploy a specific repository
Deploy-GitHubRepository -Repository "username/repo-name" -ResourceGroup "my-rg"

# Deploy with monitoring
Deploy-GitHubRepository -Monitor
```

## Functions

### Authentication Functions

- **`Connect-GitHub`** - Authenticate with GitHub using a Personal Access Token
- **`Disconnect-GitHub`** - Remove stored authentication and disconnect
- **`Test-GitHubConnection`** - Test the current GitHub connection

### Repository Management Functions

- **`Get-GitHubRepositories`** - List repositories with filtering options
- **`Select-GitHubRepository`** - Interactive repository selection menu
- **`Clone-GitHubRepository`** - Clone a repository to local machine

### Deployment Functions

- **`Deploy-GitHubRepository`** - Deploy a repository to Azure infrastructure

### Configuration Functions

- **`Set-GitHubConfiguration`** - Store configuration settings
- **`Get-GitHubConfiguration`** - Retrieve configuration settings

## GitHub Personal Access Token Setup

To use this module, you need a GitHub Personal Access Token:

1. Go to [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "HomeLab Deployment")
4. Select the following scopes:
   - `repo` (for private repositories) or `public_repo` (for public repositories only)
   - `user` (to read user information)
5. Click "Generate token"
6. Copy the token immediately (you won't be able to see it again)

## Examples

### Basic Workflow

```powershell
# 1. Connect to GitHub
Connect-GitHub

# 2. Browse your repositories
$repos = Get-GitHubRepositories -Type owner -Sort updated

# 3. Select a repository interactively
$selectedRepo = Select-GitHubRepository

# 4. Deploy the selected repository
Deploy-GitHubRepository -Monitor
```

### Advanced Repository Filtering

```powershell
# Get only PowerShell repositories
Get-GitHubRepositories -Language PowerShell

# Get private repositories sorted by creation date
Get-GitHubRepositories -Type private -Sort created -Direction desc

# Get repositories with "homelab" in the name
Get-GitHubRepositories | Where-Object { $_.Name -like "*homelab*" }
```

### Repository Cloning

```powershell
# Clone the selected repository
Clone-GitHubRepository

# Clone a specific repository to a custom path
Clone-GitHubRepository -Repository "username/repo" -Path "C:\Source\MyRepo"

# Clone a specific branch
Clone-GitHubRepository -Branch "develop" -Force
```

### Deployment Scenarios

```powershell
# Deploy to a specific resource group
Deploy-GitHubRepository -ResourceGroup "production-rg"

# Deploy with background monitoring
Deploy-GitHubRepository -BackgroundMonitor

# Deploy a specific branch
Deploy-GitHubRepository -Branch "release/v1.0" -Monitor
```

## Configuration

The module stores configuration in `~/.homelab/github-config.json`, including:

- User information (username, name, email)
- Selected repository details
- Default clone path
- Connection timestamps

## Security

- **Token Storage**: Personal Access Tokens are stored securely using Windows Credential Manager on Windows systems
- **Cross-Platform**: On non-Windows systems, tokens can be stored in environment variables
- **Minimal Permissions**: Only requires `repo` and `user` scopes
- **Secure Transmission**: All API calls use HTTPS

## Integration with HomeLab

This module integrates seamlessly with other HomeLab modules:

- **HomeLab.Azure**: Deploy repositories to Azure infrastructure
- **HomeLab.Core**: Use shared configuration and logging
- **HomeLab.Logging**: Comprehensive logging of all operations

## Troubleshooting

### Common Issues

1. **"Not connected to GitHub"**
   - Run `Connect-GitHub` to authenticate
   - Ensure your token hasn't expired

2. **"Token lacks required permissions"**
   - Regenerate your token with `repo` and `user` scopes
   - Use `Connect-GitHub -Force` to re-authenticate

3. **"Git is not installed"**
   - Install Git from [git-scm.com](https://git-scm.com/)
   - Ensure Git is in your system PATH

4. **"Repository not found"**
   - Check repository name spelling
   - Ensure you have access to the repository
   - For private repos, ensure your token has `repo` scope

### Getting Help

```powershell
# Get help for any function
Get-Help Connect-GitHub -Full
Get-Help Deploy-GitHubRepository -Examples

# Test your connection
Test-GitHubConnection

# View current configuration
Get-GitHubConfiguration
```

## Version History

- **1.0.0** - Initial release with core GitHub integration functionality

## Contributing

This module is part of the HomeLab project. Contributions are welcome!

## License

Copyright (c) 2025 Jurie Smit. All rights reserved.
