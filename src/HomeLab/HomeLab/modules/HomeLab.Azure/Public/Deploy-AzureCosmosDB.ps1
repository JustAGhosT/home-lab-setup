function Deploy-AzureCosmosDB {
    <#
    .SYNOPSIS
        Deploys an Azure Cosmos DB account.
    
    .DESCRIPTION
        Deploys an Azure Cosmos DB account with configurable parameters including
        API type, consistency level, and throughput settings.
    
    .PARAMETER ResourceGroup
        The resource group name where the Cosmos DB account will be deployed.
    
    .PARAMETER Location
        The Azure location for the deployment.
    
    .PARAMETER AccountName
        The name of the Cosmos DB account.
    
    .PARAMETER ApiType
        The API type for the Cosmos DB account (SQL, MongoDB, Cassandra, etc.).
    
    .PARAMETER DatabaseName
        The name of the database to create.
    
    .PARAMETER ContainerName
        The name of the container to create.
    
    .PARAMETER PartitionKey
        The partition key for the container.
    
    .PARAMETER ConsistencyLevel
        The consistency level for the Cosmos DB account.
    
    .PARAMETER EnableMultiRegion
        Whether to enable multi-region writes.
    
    .PARAMETER EnableAutomaticFailover
        Whether to enable automatic failover.
    
    .PARAMETER Throughput
        The throughput in request units per second (RU/s).
    
    .EXAMPLE
        Deploy-AzureCosmosDB -ResourceGroup "my-rg" -Location "southafricanorth" -AccountName "my-cosmos-account" -DatabaseName "my-database"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$Location,
        
        [Parameter(Mandatory = $true)]
        [string]$AccountName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("SQL", "MongoDB", "Cassandra", "Gremlin", "Table")]
        [string]$ApiType = "SQL",
        
        [Parameter(Mandatory = $false)]
        [string]$DatabaseName,
        
        [Parameter(Mandatory = $false)]
        [string]$ContainerName,
        
        [Parameter(Mandatory = $false)]
        [string]$PartitionKey = "/id",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Eventual", "ConsistentPrefix", "Session", "BoundedStaleness", "Strong")]
        [string]$ConsistencyLevel = "Session",
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableMultiRegion = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableAutomaticFailover = $false,
        
        [Parameter(Mandatory = $false)]
        [int]$Throughput = 400
    )
    
    try {
        Write-ColorOutput "Starting Azure Cosmos DB deployment..." -ForegroundColor Cyan
        
        # Check if resource group exists
        try {
            $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to check resource group existence. Exit code: $LASTEXITCODE"
            }
            
            if ($rgExists -ne "true") {
                Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
                az group create --name $ResourceGroup --location $Location
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create resource group '$ResourceGroup'. Exit code: $LASTEXITCODE"
                }
                Write-ColorOutput "Successfully created resource group: $ResourceGroup" -ForegroundColor Green
            }
        }
        catch {
            Write-ColorOutput "Error with resource group operations: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to handle resource group '$ResourceGroup': $($_.Exception.Message)"
        }
        
        # Determine API type for Azure CLI
        $cosmosApiType = switch ($ApiType) {
            "SQL" { "sql" }
            "MongoDB" { "mongodb" }
            "Cassandra" { "cassandra" }
            "Gremlin" { "gremlin" }
            "Table" { "table" }
        }
        
        # Create Cosmos DB account
        Write-ColorOutput "Creating Cosmos DB account: $AccountName" -ForegroundColor Yellow
        $createParams = @(
            "cosmosdb", "create",
            "--name", $AccountName,
            "--resource-group", $ResourceGroup,
            "--locations", "regionName=$Location failoverPriority=0 isZoneRedundant=false",
            "--default-consistency-level", $ConsistencyLevel,
            "--kind", $cosmosApiType
        )
        
        if ($EnableMultiRegion) {
            $createParams += "--enable-multiple-write-locations"
        }
        
        if ($EnableAutomaticFailover) {
            $createParams += "--enable-automatic-failover"
        }
        
        try {
            & az @createParams
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to create Cosmos DB account '$AccountName'. Exit code: $LASTEXITCODE"
            }
            
            Write-ColorOutput "Successfully created Cosmos DB account: $AccountName" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error creating Cosmos DB account '$AccountName': $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to create Cosmos DB account '$AccountName': $($_.Exception.Message)"
        }
        
        # Create database if specified
        if ($DatabaseName) {
            Write-ColorOutput "Creating database: $DatabaseName" -ForegroundColor Yellow
            try {
                az cosmosdb sql database create `
                    --account-name $AccountName `
                    --resource-group $ResourceGroup `
                    --name $DatabaseName
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create database '$DatabaseName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created database: $DatabaseName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating database '$DatabaseName': $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create database '$DatabaseName': $($_.Exception.Message)"
            }
        }
        
        # Create container if specified
        if ($ContainerName -and $DatabaseName) {
            Write-ColorOutput "Creating container: $ContainerName" -ForegroundColor Yellow
            try {
                az cosmosdb sql container create `
                    --account-name $AccountName `
                    --resource-group $ResourceGroup `
                    --database-name $DatabaseName `
                    --name $ContainerName `
                    --partition-key-path $PartitionKey `
                    --throughput $Throughput
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create container '$ContainerName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created container: $ContainerName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating container '$ContainerName': $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create container '$ContainerName': $($_.Exception.Message)"
            }
        }
        
        # Get connection string
        try {
            $connectionString = az cosmosdb keys list `
                --name $AccountName `
                --resource-group $ResourceGroup `
                --type connection-strings `
                --query "connectionStrings[0].connectionString" `
                --output tsv
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve connection string. Exit code: $LASTEXITCODE"
            }
            
            if ([string]::IsNullOrWhiteSpace($connectionString)) {
                throw "Connection string is empty or null. Please check if the Cosmos DB account exists and you have proper permissions."
            }
            
            Write-ColorOutput "Successfully retrieved connection string" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving connection string: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve connection string for '$AccountName': $($_.Exception.Message)"
        }
        
        # Get primary key
        try {
            $primaryKey = az cosmosdb keys list `
                --name $AccountName `
                --resource-group $ResourceGroup `
                --type keys `
                --query "primaryMasterKey" `
                --output tsv
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve primary key. Exit code: $LASTEXITCODE"
            }
            
            if ([string]::IsNullOrWhiteSpace($primaryKey)) {
                throw "Primary key is empty or null. Please check if the Cosmos DB account exists and you have proper permissions."
            }
            
            Write-ColorOutput "Successfully retrieved primary key" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving primary key: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve primary key for '$AccountName': $($_.Exception.Message)"
        }
        
        # Helper function to mask sensitive keys
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
        
        # Display deployment summary
        Write-ColorOutput "`nAzure Cosmos DB deployment completed successfully!" -ForegroundColor Green
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "Account Name: $AccountName" -ForegroundColor Gray
        Write-ColorOutput "API Type: $ApiType" -ForegroundColor Gray
        if ($DatabaseName) {
            Write-ColorOutput "Database: $DatabaseName" -ForegroundColor Gray
        }
        if ($ContainerName) {
            Write-ColorOutput "Container: $ContainerName" -ForegroundColor Gray
        }
        Write-ColorOutput "Connection String: $(Get-MaskedValue -Value $connectionString)" -ForegroundColor Gray
        Write-ColorOutput "Primary Key: $(Get-MaskedValue -Value $primaryKey)" -ForegroundColor Gray
        
        # Security warning for sensitive data
        Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
        Write-ColorOutput "The returned object contains sensitive Cosmos DB connection strings and keys." -ForegroundColor Yellow
        Write-ColorOutput "Please ensure this data is:" -ForegroundColor Yellow
        Write-ColorOutput "  • Not logged or written to files" -ForegroundColor Yellow
        Write-ColorOutput "  • Not committed to version control" -ForegroundColor Yellow
        Write-ColorOutput "  • Stored securely in production environments" -ForegroundColor Yellow
        Write-ColorOutput "  • Considered for Azure Key Vault integration" -ForegroundColor Yellow
        
        # Return deployment info
        return @{
            ResourceGroup    = $ResourceGroup
            AccountName      = $AccountName
            ApiType          = $ApiType
            DatabaseName     = $DatabaseName
            ContainerName    = $ContainerName
            ConnectionString = $connectionString
            PrimaryKey       = $primaryKey
        }
    }
    catch {
        Write-ColorOutput "Error deploying Azure Cosmos DB: $_" -ForegroundColor Red
        throw
    }
} 