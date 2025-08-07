function Configure-MLWorkspace {
    <#
    .SYNOPSIS
        Configures ML workspace settings and connections.
    
    .DESCRIPTION
        Configures settings and connections for ML workspace deployments,
        including updating application configuration files.
    
    .PARAMETER ResourceGroup
        The resource group name.
    
    .PARAMETER WorkspaceName
        The ML workspace name.
    
    .PARAMETER WorkspaceId
        The workspace ID.
    
    .PARAMETER WorkspaceUrl
        The workspace URL.
    
    .PARAMETER AccessToken
        The access token.
    
    .PARAMETER StorageAccountName
        The storage account name.
    
    .PARAMETER ApplicationInsightsName
        The Application Insights name.
    
    .PARAMETER KeyVaultName
        The Key Vault name.
    
    .PARAMETER ProjectPath
        The path to the project to configure.
    
    .EXAMPLE
        Configure-MLWorkspace -ResourceGroup "my-rg" -WorkspaceName "my-ml-workspace"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceName,
        
        [Parameter(Mandatory = $false)]
        [string]$WorkspaceId,
        
        [Parameter(Mandatory = $false)]
        [string]$WorkspaceUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$AccessToken,
        
        [Parameter(Mandatory = $false)]
        [string]$StorageAccountName,
        
        [Parameter(Mandatory = $false)]
        [string]$ApplicationInsightsName,
        
        [Parameter(Mandatory = $false)]
        [string]$KeyVaultName,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )
    
    try {
        Write-ColorOutput "Configuring ML workspace..." -ForegroundColor Cyan
        
        # Helper function to mask sensitive data
        function Get-MaskedValue {
            param([string]$Value, [int]$VisibleChars = 4)
            if ([string]::IsNullOrEmpty($Value)) {
                return "[NOT SET]"
            }
            if ($Value.Length -le $VisibleChars) {
                return "*" * $Value.Length
            }
            return "*" * ($Value.Length - $VisibleChars) + $Value.Substring($Value.Length - $VisibleChars)
        }
        
        # Get workspace details if not provided
        if (-not $WorkspaceId -or -not $WorkspaceUrl) {
            $workspaceDetails = az ml workspace show `
                --name $WorkspaceName `
                --resource-group $ResourceGroup `
                --output json | ConvertFrom-Json
            
            if (-not $WorkspaceId) {
                $WorkspaceId = $workspaceDetails.id
            }
            
            if (-not $WorkspaceUrl) {
                $WorkspaceUrl = $workspaceDetails.properties.workspaceUrl
            }
        }
        
        # Get access token if not provided
        if (-not $AccessToken) {
            $AccessToken = az ml workspace get-access-token `
                --name $WorkspaceName `
                --resource-group $ResourceGroup `
                --query "accessToken" `
                --output tsv
        }
        
        # Display connection information
        Write-ColorOutput "`nML Workspace Connection Information:" -ForegroundColor Green
        Write-ColorOutput "Workspace Name: $WorkspaceName" -ForegroundColor Gray
        Write-ColorOutput "Workspace ID: $WorkspaceId" -ForegroundColor Gray
        Write-ColorOutput "Workspace URL: $WorkspaceUrl" -ForegroundColor Gray
        Write-ColorOutput "Access Token: $(Get-MaskedValue $AccessToken)" -ForegroundColor Gray
        if ($StorageAccountName) {
            Write-ColorOutput "Storage Account: $StorageAccountName" -ForegroundColor Gray
        }
        if ($ApplicationInsightsName) {
            Write-ColorOutput "Application Insights: $ApplicationInsightsName" -ForegroundColor Gray
        }
        if ($KeyVaultName) {
            Write-ColorOutput "Key Vault: $KeyVaultName" -ForegroundColor Gray
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
                
                    if (-not $appSettings.MachineLearning) {
                        $appSettings | Add-Member -MemberType NoteProperty -Name "MachineLearning" -Value @{}
                    }
                
                    $appSettings.MachineLearning.WorkspaceName = $WorkspaceName
                    $appSettings.MachineLearning.WorkspaceId = $WorkspaceId
                    $appSettings.MachineLearning.WorkspaceUrl = $WorkspaceUrl
                    $appSettings.MachineLearning.AccessToken = $AccessToken
                    $appSettings.MachineLearning.StorageAccountName = $StorageAccountName
                    $appSettings.MachineLearning.ApplicationInsightsName = $ApplicationInsightsName
                    $appSettings.MachineLearning.KeyVaultName = $KeyVaultName
                
                    $appSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $appSettingsPath
                    Write-ColorOutput "Updated appsettings.json" -ForegroundColor Green
                    Write-ColorOutput "⚠️  Note: appsettings.json contains sensitive ML workspace access tokens - ensure it's not committed to version control" -ForegroundColor Yellow
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
                
                    if (-not $packageJson.config) {
                        $packageJson | Add-Member -MemberType NoteProperty -Name "config" -Value @{}
                    }
                
                    $packageJson.config.mlWorkspaceName = $WorkspaceName
                    $packageJson.config.mlWorkspaceId = $WorkspaceId
                    $packageJson.config.mlWorkspaceUrl = $WorkspaceUrl
                    $packageJson.config.mlAccessToken = $AccessToken
                    $packageJson.config.mlStorageAccountName = $StorageAccountName
                    $packageJson.config.mlApplicationInsightsName = $ApplicationInsightsName
                    $packageJson.config.mlKeyVaultName = $KeyVaultName
                    
                    $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath
                    Write-ColorOutput "Updated package.json" -ForegroundColor Green
                    Write-ColorOutput "⚠️  Note: package.json contains sensitive ML workspace access tokens - ensure it's not committed to version control" -ForegroundColor Yellow
                }
                catch {
                    Write-ColorOutput "Error updating package.json: $($_.Exception.Message)" -ForegroundColor Red
                    throw "Failed to update package.json: $($_.Exception.Message)"
                }
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            @"
# Azure Machine Learning Workspace Configuration
AZURE_ML_WORKSPACE_NAME=$WorkspaceName
AZURE_ML_WORKSPACE_ID=$WorkspaceId
AZURE_ML_WORKSPACE_URL=$WorkspaceUrl
AZURE_ML_ACCESS_TOKEN=$AccessToken
AZURE_ML_STORAGE_ACCOUNT_NAME=$StorageAccountName
AZURE_ML_APPLICATION_INSIGHTS_NAME=$ApplicationInsightsName
AZURE_ML_KEY_VAULT_NAME=$KeyVaultName
"@ | Set-Content -Path $envPath
            Write-ColorOutput "Created .env file" -ForegroundColor Green
            
            # Security warning for .env file
            Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
            Write-ColorOutput "The .env file contains sensitive ML workspace access tokens." -ForegroundColor Yellow
            Write-ColorOutput "Please ensure this file is:" -ForegroundColor Yellow
            Write-ColorOutput "  • Added to .gitignore to prevent accidental commit to version control" -ForegroundColor Yellow
            Write-ColorOutput "  • Protected with appropriate file permissions" -ForegroundColor Yellow
            Write-ColorOutput "  • Not shared or exposed in public repositories" -ForegroundColor Yellow
            Write-ColorOutput "  • Considered for secure secret management in production environments" -ForegroundColor Yellow
            Write-ColorOutput "File location: $envPath" -ForegroundColor Gray
        }
        
        # Save connection information to a configuration file
        $userProfile = [Environment]::GetFolderPath('UserProfile')
        $configPath = Join-Path -Path $userProfile -ChildPath ".homelab\ml-workspace-connections.json"
        $configDir = Split-Path -Path $configPath -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $connectionConfig = @{
            ResourceGroup           = $ResourceGroup
            WorkspaceName           = $WorkspaceName
            WorkspaceId             = $WorkspaceId
            WorkspaceUrl            = $WorkspaceUrl
            AccessToken             = $AccessToken
            StorageAccountName      = $StorageAccountName
            ApplicationInsightsName = $ApplicationInsightsName
            KeyVaultName            = $KeyVaultName
            CreatedAt               = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        try {
            $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath -ErrorAction Stop
            Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
            Write-ColorOutput "⚠️  Note: Connection config contains sensitive ML workspace access tokens - ensure file is protected" -ForegroundColor Yellow
        }
        catch {
            Write-ColorOutput "Error saving connection configuration: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to save connection configuration: $($_.Exception.Message)"
        }
        
        Write-ColorOutput "`nML workspace configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring ML workspace: $_" -ForegroundColor Red
        throw
    }
} 