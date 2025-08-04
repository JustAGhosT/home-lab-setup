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
        
        # Get connection string and primary key if not provided
        if (-not $ConnectionString) {
            $ConnectionString = az cosmosdb keys list `
                --name $AccountName `
                --resource-group $ResourceGroup `
                --type connection-strings `
                --query "connectionStrings[0].connectionString" `
                --output tsv
        }
        
        if (-not $PrimaryKey) {
            $PrimaryKey = az cosmosdb keys list `
                --name $AccountName `
                --resource-group $ResourceGroup `
                --type keys `
                --query "primaryMasterKey" `
                --output tsv
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
        Write-ColorOutput "Connection String: $ConnectionString" -ForegroundColor Gray
        Write-ColorOutput "Primary Key: $PrimaryKey" -ForegroundColor Gray
        
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
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
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
        }
        
        # Save connection information to a configuration file
        $configPath = Join-Path -Path $env:USERPROFILE -ChildPath ".homelab\cosmos-connections.json"
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
        
        $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath
        Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
        
        Write-ColorOutput "`nCosmos DB connection configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring Cosmos DB connections: $_" -ForegroundColor Red
        throw
    }
} 