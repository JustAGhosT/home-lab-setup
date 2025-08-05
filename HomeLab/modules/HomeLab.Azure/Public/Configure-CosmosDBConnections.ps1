function Configure-CosmosDBConnections {
    <#
    .SYNOPSIS
        Configures Cosmos DB connection strings and settings.
    
    .DESCRIPTION
        Configures connection strings and settings for Cosmos DB deployments,
        including updating application configuration files.
    
    .PARAMETER ResourceGroup
        The resource group name.
    
    .PARAMETER AccountName
        The Cosmos DB account name.
    
    .PARAMETER DatabaseName
        The database name.
    
    .PARAMETER ContainerName
        The container name.
    
    .PARAMETER ApiType
        The API type (SQL, MongoDB, etc.).
    
    .PARAMETER ConnectionString
        The connection string.
    
    .PARAMETER PrimaryKey
        The primary key.
    
    .PARAMETER ProjectPath
        The path to the project to configure.
    
    .EXAMPLE
        Configure-CosmosDBConnections -ResourceGroup "my-rg" -AccountName "my-cosmos-account" -DatabaseName "my-database"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$AccountName,
        
        [Parameter(Mandatory = $false)]
        [string]$DatabaseName,
        
        [Parameter(Mandatory = $false)]
        [string]$ContainerName,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiType = "SQL",
        
        [Parameter(Mandatory = $false)]
        [string]$ConnectionString,
        
        [Parameter(Mandatory = $false)]
        [string]$PrimaryKey,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )
    
    try {
        Write-ColorOutput "Configuring Cosmos DB connections..." -ForegroundColor Cyan
        
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
        
        # Get connection string and primary key if not provided
        if (-not $ConnectionString) {
            $azArgs = @(
                "cosmosdb", "keys", "list",
                "--name", $AccountName,
                "--resource-group", $ResourceGroup,
                "--type", "connection-strings",
                "--query", "connectionStrings[0].connectionString",
                "--output", "tsv"
            )
            $ConnectionString = & az @azArgs
        }
        
        if (-not $PrimaryKey) {
            $azArgs = @(
                "cosmosdb", "keys", "list",
                "--name", $AccountName,
                "--resource-group", $ResourceGroup,
                "--type", "keys",
                "--query", "primaryMasterKey",
                "--output", "tsv"
            )
            $PrimaryKey = & az @azArgs
        }
        
        # Build Cosmos DB endpoint URL
        $endpointUrl = "https://$AccountName.documents.azure.com:443/"
        
        # Display connection information
        Write-ColorOutput "`nCosmos DB Connection Information:" -ForegroundColor Green
        Write-ColorOutput "Account: $AccountName" -ForegroundColor Gray
        Write-ColorOutput "API Type: $ApiType" -ForegroundColor Gray
        Write-ColorOutput "Endpoint: $endpointUrl" -ForegroundColor Gray
        if ($DatabaseName) {
            Write-ColorOutput "Database: $DatabaseName" -ForegroundColor Gray
        }
        if ($ContainerName) {
            Write-ColorOutput "Container: $ContainerName" -ForegroundColor Gray
        }
        Write-ColorOutput "Connection String: $(Get-MaskedValue -Value $ConnectionString)" -ForegroundColor Gray
        Write-ColorOutput "Primary Key: $(Get-MaskedValue -Value $PrimaryKey)" -ForegroundColor Gray
        
        # Update project configuration files if project path is provided
        if ($ProjectPath -and (Test-Path -Path $ProjectPath)) {
            Write-ColorOutput "`nUpdating project configuration files..." -ForegroundColor Yellow
            
            # Update appsettings.json for .NET projects
            $appSettingsPath = Join-Path -Path $ProjectPath -ChildPath "appsettings.json"
            if (Test-Path -Path $appSettingsPath) {
                Write-ColorOutput "Updating appsettings.json..." -ForegroundColor Gray
                $appSettings = Get-Content -Path $appSettingsPath | ConvertFrom-Json
                
                if (-not $appSettings.CosmosDb) {
                    $appSettings | Add-Member -MemberType NoteProperty -Name "CosmosDb" -Value @{}
                }
                
                $appSettings.CosmosDb.Endpoint = $endpointUrl
                $appSettings.CosmosDb.Key = $PrimaryKey
                $appSettings.CosmosDb.DatabaseId = $DatabaseName
                $appSettings.CosmosDb.ContainerId = $ContainerName
                $appSettings.CosmosDb.ConnectionString = $ConnectionString
                
                $appSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $appSettingsPath
                Write-ColorOutput "Updated appsettings.json" -ForegroundColor Green
                Write-ColorOutput "⚠️  Note: appsettings.json contains sensitive Cosmos DB keys - ensure it's not committed to version control" -ForegroundColor Yellow
            }
            
            # Update package.json for Node.js projects
            $packageJsonPath = Join-Path -Path $ProjectPath -ChildPath "package.json"
            if (Test-Path -Path $packageJsonPath) {
                Write-ColorOutput "Updating package.json..." -ForegroundColor Gray
                $packageJson = Get-Content -Path $packageJsonPath | ConvertFrom-Json
                
                if (-not $packageJson.config) {
                    $packageJson | Add-Member -MemberType NoteProperty -Name "config" -Value @{}
                }
                
                $packageJson.config.cosmosDbEndpoint = $endpointUrl
                $packageJson.config.cosmosDbKey = $PrimaryKey
                $packageJson.config.cosmosDbDatabase = $DatabaseName
                $packageJson.config.cosmosDbContainer = $ContainerName
                $packageJson.config.cosmosDbConnectionString = $ConnectionString
                
                $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath
                Write-ColorOutput "Updated package.json" -ForegroundColor Green
                Write-ColorOutput "⚠️  Note: package.json contains sensitive Cosmos DB keys - ensure it's not committed to version control" -ForegroundColor Yellow
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            
            if (Test-Path -Path $envPath) {
                $overwrite = Read-Host "`.env file already exists. Overwrite? (y/N)"
                if ($overwrite -ne "y" -and $overwrite -ne "Y") {
                    Write-ColorOutput "Skipping .env file creation to preserve existing data." -ForegroundColor Yellow
                }
                else {
                    @"
# Cosmos DB Configuration
COSMOS_DB_ENDPOINT=$endpointUrl
COSMOS_DB_KEY=$PrimaryKey
COSMOS_DB_DATABASE=$DatabaseName
COSMOS_DB_CONTAINER=$ContainerName
COSMOS_DB_CONNECTION_STRING=$ConnectionString
COSMOS_DB_API_TYPE=$ApiType
"@ | Set-Content -Path $envPath
                    Write-ColorOutput "Updated .env file" -ForegroundColor Green
                    
                    # Security warning for .env file
                    Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
                    Write-ColorOutput "The .env file contains sensitive Cosmos DB connection strings and keys." -ForegroundColor Yellow
                    Write-ColorOutput "Please ensure this file is:" -ForegroundColor Yellow
                    Write-ColorOutput "  • Added to .gitignore to prevent accidental commit to version control" -ForegroundColor Yellow
                    Write-ColorOutput "  • Protected with appropriate file permissions" -ForegroundColor Yellow
                    Write-ColorOutput "  • Not shared or exposed in public repositories" -ForegroundColor Yellow
                    Write-ColorOutput "  • Considered for secure secret management in production environments" -ForegroundColor Yellow
                    Write-ColorOutput "File location: $envPath" -ForegroundColor Gray
                }
            }
            else {
                @"
# Cosmos DB Configuration
COSMOS_DB_ENDPOINT=$endpointUrl
COSMOS_DB_KEY=$PrimaryKey
COSMOS_DB_DATABASE=$DatabaseName
COSMOS_DB_CONTAINER=$ContainerName
COSMOS_DB_CONNECTION_STRING=$ConnectionString
COSMOS_DB_API_TYPE=$ApiType
"@ | Set-Content -Path $envPath
                Write-ColorOutput "Created .env file" -ForegroundColor Green
                
                # Security warning for .env file
                Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
                Write-ColorOutput "The .env file contains sensitive Cosmos DB connection strings and keys." -ForegroundColor Yellow
                Write-ColorOutput "Please ensure this file is:" -ForegroundColor Yellow
                Write-ColorOutput "  • Added to .gitignore to prevent accidental commit to version control" -ForegroundColor Yellow
                Write-ColorOutput "  • Protected with appropriate file permissions" -ForegroundColor Yellow
                Write-ColorOutput "  • Not shared or exposed in public repositories" -ForegroundColor Yellow
                Write-ColorOutput "  • Considered for secure secret management in production environments" -ForegroundColor Yellow
                Write-ColorOutput "File location: $envPath" -ForegroundColor Gray
            }
        }
        
        # Save connection information to a configuration file
        $userProfile = [Environment]::GetFolderPath('UserProfile')
        $configPath = Join-Path -Path $userProfile -ChildPath ".homelab\cosmos-connections.json"
        $configDir = Split-Path -Path $configPath -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $connectionConfig = @{
            ResourceGroup    = $ResourceGroup
            AccountName      = $AccountName
            DatabaseName     = $DatabaseName
            ContainerName    = $ContainerName
            ApiType          = $ApiType
            EndpointUrl      = $endpointUrl
            ConnectionString = $ConnectionString
            PrimaryKey       = $PrimaryKey
            CreatedAt        = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        try {
            $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath -ErrorAction Stop
            Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
            Write-ColorOutput "⚠️  Note: Connection config contains sensitive Cosmos DB keys - ensure file is protected" -ForegroundColor Yellow
        }
        catch {
            Write-ColorOutput "Error saving connection configuration: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to save connection configuration: $($_.Exception.Message)"
        }
        
        Write-ColorOutput "`nCosmos DB connection configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring Cosmos DB connections: $_" -ForegroundColor Red
        throw
    }
} 