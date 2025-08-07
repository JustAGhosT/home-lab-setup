function Configure-MultiCloudEndpoints {
    <#
    .SYNOPSIS
        Configures multi-cloud endpoints and settings.
    
    .DESCRIPTION
        Configures endpoints and settings for multi-cloud deployments,
        including updating application configuration files.
    
    .PARAMETER ResourceGroup
        The resource group name.
    
    .PARAMETER ProjectName
        The multi-cloud project name.
    
    .PARAMETER CloudProviders
        Array of cloud providers.
    
    .PARAMETER AzureResources
        Azure resources configuration.
    
    .PARAMETER ConfigurationFiles
        Configuration files paths.
    
    .PARAMETER ProjectPath
        The path to the project to configure.
    
    .EXAMPLE
        Configure-MultiCloudEndpoints -ResourceGroup "my-rg" -ProjectName "my-multicloud-project"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$CloudProviders = @("Azure"),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AzureResources,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConfigurationFiles,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )
    
    try {
        Write-ColorOutput "Configuring multi-cloud endpoints..." -ForegroundColor Cyan
        
        # Helper function for robust property existence checking
        function Test-PropertyExists {
            param([object]$Object, [string]$PropertyName)
            return $Object.PSObject.Properties.Name -contains $PropertyName
        }
        
        # Helper function to escape input for .env files while preserving integrity
        function Get-EscapedValue {
            param([string]$Value)
            if ([string]::IsNullOrEmpty($Value)) {
                return ""
            }
            
            # Escape special characters that could cause command injection while preserving valid inputs
            $escaped = $Value
            
            # Escape double quotes and backslashes for .env file format
            $escaped = $escaped -replace '\\', '\\'
            $escaped = $escaped -replace '"', '\"'
            
            # Escape newlines and carriage returns
            $escaped = $escaped -replace '[\r\n]', ' '
            
            # Escape backticks that could be used for command substitution
            $escaped = $escaped -replace '`', '\`'
            
            # Escape dollar signs that could be used for variable expansion
            $escaped = $escaped -replace '\$', '\$'
            
            # Escape semicolons that could be used for command chaining
            $escaped = $escaped -replace ';', '\;'
            
            # Escape pipe characters that could be used for command piping
            $escaped = $escaped -replace '\|', '\|'
            
            # Escape ampersands that could be used for background processes
            $escaped = $escaped -replace '&', '\&'
            
            # Escape angle brackets that could be used for redirection
            $escaped = $escaped -replace '<', '\<'
            $escaped = $escaped -replace '>', '\>'
            
            # Escape exclamation marks that could be used for history expansion
            $escaped = $escaped -replace '!', '\!'
            
            # Escape asterisks and question marks that could be used for globbing
            $escaped = $escaped -replace '\*', '\*'
            $escaped = $escaped -replace '\?', '\?'
            
            # Escape square brackets that could be used for character classes
            $escaped = $escaped -replace '\[', '\[' 
            $escaped = $escaped -replace '\]', '\]'
            
            # Escape curly braces that could be used for brace expansion
            $escaped = $escaped -replace '\{', '\{'
            $escaped = $escaped -replace '\}', '\}'
            
            # Escape parentheses that could be used for command grouping
            $escaped = $escaped -replace '\(', '\('
            $escaped = $escaped -replace '\)', '\)'
            
            # Trim whitespace and limit length to prevent buffer overflow
            $escaped = $escaped.Trim()
            if ($escaped.Length -gt 1000) {
                $escaped = $escaped.Substring(0, 1000)
            }
            
            return $escaped
        }
        
        # Display multi-cloud configuration information
        Write-ColorOutput "`nMulti-Cloud Configuration Information:" -ForegroundColor Green
        Write-ColorOutput "Project Name: $ProjectName" -ForegroundColor Gray
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "Cloud Providers: $($CloudProviders -join ', ')" -ForegroundColor Gray
        
        if ($AzureResources) {
            Write-ColorOutput "Azure Resources:" -ForegroundColor Gray
            if ($AzureResources.ContainerRegistry) {
                Write-ColorOutput "  - Container Registry: $($AzureResources.ContainerRegistry)" -ForegroundColor Gray
            }
            if ($AzureResources.KeyVault) {
                Write-ColorOutput "  - Key Vault: $($AzureResources.KeyVault)" -ForegroundColor Gray
            }
            if ($AzureResources.StorageAccount) {
                Write-ColorOutput "  - Storage Account: $($AzureResources.StorageAccount)" -ForegroundColor Gray
            }
            if ($AzureResources.LogAnalyticsWorkspace) {
                Write-ColorOutput "  - Log Analytics Workspace: $($AzureResources.LogAnalyticsWorkspace)" -ForegroundColor Gray
            }
            if ($AzureResources.AKSCluster) {
                Write-ColorOutput "  - AKS Cluster: $($AzureResources.AKSCluster)" -ForegroundColor Gray
            }
        }
        
        if ($ConfigurationFiles) {
            Write-ColorOutput "Configuration Files:" -ForegroundColor Gray
            if ($ConfigurationFiles.Terraform) {
                Write-ColorOutput "  - Terraform: $($ConfigurationFiles.Terraform)" -ForegroundColor Gray
            }
            if ($ConfigurationFiles.Bicep) {
                Write-ColorOutput "  - Bicep: $($ConfigurationFiles.Bicep)" -ForegroundColor Gray
            }
            if ($ConfigurationFiles.CloudFormation) {
                Write-ColorOutput "  - CloudFormation: $($ConfigurationFiles.CloudFormation)" -ForegroundColor Gray
            }
            if ($ConfigurationFiles.MultiCloudConfig) {
                Write-ColorOutput "  - Multi-Cloud Config: $($ConfigurationFiles.MultiCloudConfig)" -ForegroundColor Gray
            }
        }
        
        # Update project configuration files if project path is provided
        if ($ProjectPath -and (Test-Path -Path $ProjectPath)) {
            Write-ColorOutput "`nUpdating project configuration files..." -ForegroundColor Yellow
            
            # Update appsettings.json for .NET projects
            $appSettingsPath = Join-Path -Path $ProjectPath -ChildPath "appsettings.json"
            if (Test-Path -Path $appSettingsPath) {
                Write-ColorOutput "Updating appsettings.json..." -ForegroundColor Gray
                try {
                    $appSettings = Get-Content -Path $appSettingsPath | ConvertFrom-Json
                    
                    if (-not (Test-PropertyExists -Object $appSettings -PropertyName "MultiCloud")) {
                        $appSettings | Add-Member -MemberType NoteProperty -Name "MultiCloud" -Value @{}
                    }
                    
                    $appSettings.MultiCloud.ProjectName = $ProjectName
                    $appSettings.MultiCloud.ResourceGroup = $ResourceGroup
                    $appSettings.MultiCloud.CloudProviders = $CloudProviders
                    
                    if ($AzureResources) {
                        $appSettings.MultiCloud.AzureResources = $AzureResources
                    }
                    
                    if ($ConfigurationFiles) {
                        $appSettings.MultiCloud.ConfigurationFiles = $ConfigurationFiles
                    }
                    
                    # Atomic write to appsettings.json
                    $tempAppSettingsPath = $appSettingsPath + ".tmp"
                    try {
                        $appSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $tempAppSettingsPath -ErrorAction Stop
                        Move-Item -Path $tempAppSettingsPath -Destination $appSettingsPath -Force
                        Write-ColorOutput "Updated appsettings.json" -ForegroundColor Green
                        Write-ColorOutput "⚠️  Note: appsettings.json contains multi-cloud configuration data - ensure it's not committed to version control" -ForegroundColor Yellow
                    }
                    catch {
                        if (Test-Path -Path $tempAppSettingsPath) {
                            Remove-Item -Path $tempAppSettingsPath -Force -ErrorAction SilentlyContinue
                        }
                        throw
                    }
                }
                catch {
                    Write-ColorOutput "Error updating appsettings.json: $($_.Exception.Message)" -ForegroundColor Red
                    throw "Failed to update appsettings.json: $($_.Exception.Message)"
                }
            }
            
            # Update package.json for Node.js projects
            $packageJsonPath = Join-Path -Path $ProjectPath -ChildPath "package.json"
            if (Test-Path -Path $packageJsonPath) {
                Write-ColorOutput "Updating package.json..." -ForegroundColor Gray
                try {
                    $packageJson = Get-Content -Path $packageJsonPath | ConvertFrom-Json
                    
                    if (-not (Test-PropertyExists -Object $packageJson -PropertyName "config")) {
                        $packageJson | Add-Member -MemberType NoteProperty -Name "config" -Value @{}
                    }
                    
                    $packageJson.config.multicloudProjectName = $ProjectName
                    $packageJson.config.multicloudResourceGroup = $ResourceGroup
                    $packageJson.config.multicloudCloudProviders = $CloudProviders
                    
                    if ($AzureResources) {
                        $packageJson.config.multicloudAzureResources = $AzureResources
                    }
                    
                    if ($ConfigurationFiles) {
                        $packageJson.config.multicloudConfigurationFiles = $ConfigurationFiles
                    }
                    
                    # Atomic write to package.json
                    $tempPackageJsonPath = $packageJsonPath + ".tmp"
                    try {
                        $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $tempPackageJsonPath -ErrorAction Stop
                        Move-Item -Path $tempPackageJsonPath -Destination $packageJsonPath -Force
                        Write-ColorOutput "Updated package.json" -ForegroundColor Green
                        Write-ColorOutput "⚠️  Note: package.json contains multi-cloud configuration data - ensure it's not committed to version control" -ForegroundColor Yellow
                    }
                    catch {
                        if (Test-Path -Path $tempPackageJsonPath) {
                            Remove-Item -Path $tempPackageJsonPath -Force -ErrorAction SilentlyContinue
                        }
                        throw
                    }
                }
                catch {
                    Write-ColorOutput "Error updating package.json: $($_.Exception.Message)" -ForegroundColor Red
                    throw "Failed to update package.json: $($_.Exception.Message)"
                }
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            
            # Escape input values to prevent command injection while preserving integrity
            $escapedProjectName = Get-EscapedValue -Value $ProjectName
            $escapedResourceGroup = Get-EscapedValue -Value $ResourceGroup
            $escapedCloudProviders = ($CloudProviders | ForEach-Object { Get-EscapedValue -Value $_ }) -join ','
            
            # Create temporary file for atomic write
            $tempEnvPath = $envPath + ".tmp"
            
            try {
                @"
# Multi-Cloud Configuration
MULTICLOUD_PROJECT_NAME=$escapedProjectName
MULTICLOUD_RESOURCE_GROUP=$escapedResourceGroup
MULTICLOUD_CLOUD_PROVIDERS=$escapedCloudProviders
"@ | Set-Content -Path $tempEnvPath -ErrorAction Stop
                
                # Atomic move to replace original file
                Move-Item -Path $tempEnvPath -Destination $envPath -Force
                Write-ColorOutput "Created .env file" -ForegroundColor Green
            
                # Security warning for .env file
                Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
                Write-ColorOutput "The .env file contains multi-cloud configuration data." -ForegroundColor Yellow
                Write-ColorOutput "Please ensure this file is:" -ForegroundColor Yellow
                Write-ColorOutput "  • Added to .gitignore to prevent accidental commit to version control" -ForegroundColor Yellow
                Write-ColorOutput "  • Protected with appropriate file permissions" -ForegroundColor Yellow
                Write-ColorOutput "  • Not shared or exposed in public repositories" -ForegroundColor Yellow
                Write-ColorOutput "  • Considered for secure secret management in production environments" -ForegroundColor Yellow
                Write-ColorOutput "File location: $envPath" -ForegroundColor Gray
            }
            catch {
                # Clean up temporary file if it exists
                if (Test-Path -Path $tempEnvPath) {
                    Remove-Item -Path $tempEnvPath -Force -ErrorAction SilentlyContinue
                }
                Write-ColorOutput "Error creating .env file: $($_.Exception.Message)" -ForegroundColor Red
                Write-ColorOutput "This may be due to file permissions or disk space issues." -ForegroundColor Yellow
                throw "Failed to create .env file: $($_.Exception.Message)"
            }
        }
        
        # Save connection information to a configuration file
        $userProfile = [Environment]::GetFolderPath('UserProfile')
        $configPath = Join-Path -Path $userProfile -ChildPath ".homelab\multicloud-connections.json"
        $configDir = Split-Path -Path $configPath -Parent
        
        try {
            if (-not (Test-Path -Path $configDir)) {
                New-Item -ItemType Directory -Path $configDir -Force | Out-Null
            }
            
            $connectionConfig = @{
                ProjectName        = $ProjectName
                ResourceGroup      = $ResourceGroup
                CloudProviders     = $CloudProviders
                AzureResources     = $AzureResources
                ConfigurationFiles = $ConfigurationFiles
                CreatedAt          = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
            
            $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath
            Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
            Write-ColorOutput "⚠️  Note: Connection config contains multi-cloud configuration data - ensure file is protected" -ForegroundColor Yellow
        }
        catch {
            Write-ColorOutput "Error saving connection configuration: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to save connection configuration: $($_.Exception.Message)"
        }
        
        Write-ColorOutput "`nMulti-cloud endpoint configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring multi-cloud endpoints: $_" -ForegroundColor Red
        throw
    }
} 