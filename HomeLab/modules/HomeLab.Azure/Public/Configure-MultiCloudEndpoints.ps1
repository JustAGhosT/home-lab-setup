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
                $appSettings = Get-Content -Path $appSettingsPath | ConvertFrom-Json
                
                if (-not $appSettings.MultiCloud) {
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
                
                $appSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $appSettingsPath
                Write-ColorOutput "Updated appsettings.json" -ForegroundColor Green
            }
            
            # Update package.json for Node.js projects
            $packageJsonPath = Join-Path -Path $ProjectPath -ChildPath "package.json"
            if (Test-Path -Path $packageJsonPath) {
                Write-ColorOutput "Updating package.json..." -ForegroundColor Gray
                $packageJson = Get-Content -Path $packageJsonPath | ConvertFrom-Json
                
                if (-not $packageJson.config) {
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
                
                $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath
                Write-ColorOutput "Updated package.json" -ForegroundColor Green
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            @"
# Multi-Cloud Configuration
MULTICLOUD_PROJECT_NAME=$ProjectName
MULTICLOUD_RESOURCE_GROUP=$ResourceGroup
MULTICLOUD_CLOUD_PROVIDERS=$($CloudProviders -join ',')
"@ | Set-Content -Path $envPath
            Write-ColorOutput "Created .env file" -ForegroundColor Green
        }
        
        # Save connection information to a configuration file
        $configPath = Join-Path -Path $env:USERPROFILE -ChildPath ".homelab\multicloud-connections.json"
        $configDir = Split-Path -Path $configPath -Parent
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
        
        Write-ColorOutput "`nMulti-cloud endpoint configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring multi-cloud endpoints: $_" -ForegroundColor Red
        throw
    }
} 