function Configure-BlobStorageConnection {
    <#
    .SYNOPSIS
        Configures blob storage connection strings and settings.
    
    .DESCRIPTION
        Configures connection strings and settings for blob storage deployments,
        including updating application configuration files.
    
    .PARAMETER ResourceGroup
        The resource group name.
    
    .PARAMETER StorageAccountName
        The storage account name.
    
    .PARAMETER ContainerNames
        Array of container names.
    
    .PARAMETER ConnectionString
        The connection string.
    
    .PARAMETER StorageKey
        The storage account key.
    
    .PARAMETER StorageUrl
        The storage account URL.
    
    .PARAMETER ProjectPath
        The path to the project to configure.
    
    .EXAMPLE
        Configure-BlobStorageConnection -ResourceGroup "my-rg" -StorageAccountName "mystorageaccount"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$StorageAccountName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ContainerNames = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$ConnectionString,
        
        [Parameter(Mandatory = $false)]
        [string]$StorageKey,
        
        [Parameter(Mandatory = $false)]
        [string]$StorageUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )
    
    try {
        Write-ColorOutput "Configuring blob storage connections..." -ForegroundColor Cyan
        
        # Validate Azure CLI availability and authentication
        Write-ColorOutput "Validating Azure CLI availability..." -ForegroundColor Yellow
        try {
            $azVersion = az version --output json 2>$null
            if (-not $azVersion) {
                throw "Azure CLI is not installed or not available in PATH"
            }
            Write-ColorOutput "Azure CLI is available" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error: Azure CLI is not available. Please install Azure CLI and try again." -ForegroundColor Red
            throw "Azure CLI validation failed: $($_.Exception.Message)"
        }
        
        # Check Azure authentication
        Write-ColorOutput "Checking Azure authentication..." -ForegroundColor Yellow
        try {
            $account = az account show --output json 2>$null
            if (-not $account) {
                Write-ColorOutput "Not authenticated to Azure. Please run 'az login' first." -ForegroundColor Red
                throw "Azure authentication required"
            }
            Write-ColorOutput "Azure authentication verified" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error: Azure authentication failed. Please run 'az login' and try again." -ForegroundColor Red
            throw "Azure authentication failed: $($_.Exception.Message)"
        }
        
        # Get connection string and storage key if not provided
        if (-not $ConnectionString) {
            Write-ColorOutput "Retrieving connection string..." -ForegroundColor Yellow
            $ConnectionString = az storage account show-connection-string `
                --name $StorageAccountName `
                --resource-group $ResourceGroup `
                --query "connectionString" `
                --output tsv
        }
        
        if (-not $StorageKey) {
            Write-ColorOutput "Retrieving storage account key..." -ForegroundColor Yellow
            $StorageKey = az storage account keys list `
                --account-name $StorageAccountName `
                --resource-group $ResourceGroup `
                --query "[0].value" `
                --output tsv
        }
        
        if (-not $StorageUrl) {
            $StorageUrl = "https://$StorageAccountName.blob.core.windows.net"
        }
        
        # Display connection information (without sensitive data)
        Write-ColorOutput "`nBlob Storage Connection Information:" -ForegroundColor Green
        Write-ColorOutput "Storage Account: $StorageAccountName" -ForegroundColor Gray
        Write-ColorOutput "Storage URL: $StorageUrl" -ForegroundColor Gray
        if ($ContainerNames.Count -gt 0) {
            Write-ColorOutput "Containers: $($ContainerNames -join ', ')" -ForegroundColor Gray
        }
        Write-ColorOutput "Connection String: [REDACTED]" -ForegroundColor Gray
        Write-ColorOutput "Storage Key: [REDACTED]" -ForegroundColor Gray
        
        # Update project configuration files if project path is provided
        if ($ProjectPath -and (Test-Path -Path $ProjectPath)) {
            Write-ColorOutput "`nUpdating project configuration files..." -ForegroundColor Yellow
            
            # Update appsettings.json for .NET projects
            $appSettingsPath = Join-Path -Path $ProjectPath -ChildPath "appsettings.json"
            if (Test-Path -Path $appSettingsPath) {
                Write-ColorOutput "Updating appsettings.json..." -ForegroundColor Gray
                try {
                    $appSettings = Get-Content -Path $appSettingsPath | ConvertFrom-Json
                    
                    if (-not $appSettings.AzureStorage) {
                        $appSettings | Add-Member -MemberType NoteProperty -Name "AzureStorage" -Value @{}
                    }
                    
                    $appSettings.AzureStorage.ConnectionString = $ConnectionString
                    $appSettings.AzureStorage.AccountName = $StorageAccountName
                    $appSettings.AzureStorage.AccountKey = $StorageKey
                    $appSettings.AzureStorage.BlobServiceUri = $StorageUrl
                    $appSettings.AzureStorage.Containers = $ContainerNames
                    
                    $appSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $appSettingsPath
                    Write-ColorOutput "Updated appsettings.json" -ForegroundColor Green
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
                    
                    $packageJson.config.azureStorageConnectionString = $ConnectionString
                    $packageJson.config.azureStorageAccountName = $StorageAccountName
                    $packageJson.config.azureStorageAccountKey = $StorageKey
                    $packageJson.config.azureStorageBlobUrl = $StorageUrl
                    $packageJson.config.azureStorageContainers = $ContainerNames
                    
                    $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath
                    Write-ColorOutput "Updated package.json" -ForegroundColor Green
                }
                catch {
                    Write-ColorOutput "Error updating package.json: $($_.Exception.Message)" -ForegroundColor Red
                    throw "Failed to update package.json: $($_.Exception.Message)"
                }
            }
            
            # Update .env file for environment variables (preserving existing content)
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Updating .env file..." -ForegroundColor Gray
            
            # Read existing .env content if it exists
            $existingEnvContent = @()
            if (Test-Path -Path $envPath) {
                try {
                    $existingEnvContent = Get-Content -Path $envPath -ErrorAction Stop
                    Write-ColorOutput "Preserving existing .env file content" -ForegroundColor Gray
                }
                catch {
                    Write-ColorOutput "Warning: Could not read existing .env file: $($_.Exception.Message)" -ForegroundColor Yellow
                    $existingEnvContent = @()
                }
            }
            
            # Create new storage configuration lines
            $storageEnvLines = @(
                "# Azure Blob Storage Configuration",
                "AZURE_STORAGE_CONNECTION_STRING=$ConnectionString",
                "AZURE_STORAGE_ACCOUNT_NAME=$StorageAccountName",
                "AZURE_STORAGE_ACCOUNT_KEY=$StorageKey",
                "AZURE_STORAGE_BLOB_URL=$StorageUrl",
                "AZURE_STORAGE_CONTAINERS=$($ContainerNames -join ',')"
            )
            
            # Filter out existing storage-related lines and add new ones
            $filteredContent = $existingEnvContent | Where-Object {
                $_ -notmatch "^# Azure Blob Storage Configuration" -and
                $_ -notmatch "^AZURE_STORAGE_"
            }
            
            # Combine filtered content with new storage configuration
            $updatedEnvContent = $filteredContent + $storageEnvLines
            
            # Write back to .env file
            try {
                $updatedEnvContent | Set-Content -Path $envPath -ErrorAction Stop
                Write-ColorOutput "Updated .env file" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error updating .env file: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to update .env file: $($_.Exception.Message)"
            }
        }
        
        # Save connection information to a configuration file
        $configPath = Join-Path -Path $env:USERPROFILE -ChildPath ".homelab\blob-storage-connections.json"
        $configDir = Split-Path -Path $configPath -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $connectionConfig = @{
            ResourceGroup      = $ResourceGroup
            StorageAccountName = $StorageAccountName
            ContainerNames     = $ContainerNames
            StorageUrl         = $StorageUrl
            ConnectionString   = $ConnectionString
            StorageKey         = $StorageKey
            CreatedAt          = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        try {
            $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath -ErrorAction Stop
            Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error saving connection configuration: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to save connection configuration: $($_.Exception.Message)"
        }
        
        Write-ColorOutput "`nBlob storage connection configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring blob storage connections: $_" -ForegroundColor Red
        throw
    }
} 