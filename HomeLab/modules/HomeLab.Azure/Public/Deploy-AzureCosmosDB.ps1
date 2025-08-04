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
        $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
        if ($rgExists -ne "true") {
            Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
            az group create --name $ResourceGroup --location $Location
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
        
        az $createParams
        
        # Create database if specified
        if ($DatabaseName) {
            Write-ColorOutput "Creating database: $DatabaseName" -ForegroundColor Yellow
            az cosmosdb sql database create `
                --account-name $AccountName `
                --resource-group $ResourceGroup `
                --name $DatabaseName
        }
        
        # Create container if specified
        if ($ContainerName -and $DatabaseName) {
            Write-ColorOutput "Creating container: $ContainerName" -ForegroundColor Yellow
            az cosmosdb sql container create `
                --account-name $AccountName `
                --resource-group $ResourceGroup `
                --database-name $DatabaseName `
                --name $ContainerName `
                --partition-key-path $PartitionKey `
                --throughput $Throughput
        }
        
        # Get connection string
        $connectionString = az cosmosdb keys list `
            --name $AccountName `
            --resource-group $ResourceGroup `
            --type connection-strings `
            --query "connectionStrings[0].connectionString" `
            --output tsv
        
        # Get primary key
        $primaryKey = az cosmosdb keys list `
            --name $AccountName `
            --resource-group $ResourceGroup `
            --type keys `
            --query "primaryMasterKey" `
            --output tsv
        
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
        Write-ColorOutput "Connection String: $connectionString" -ForegroundColor Gray
        Write-ColorOutput "Primary Key: $primaryKey" -ForegroundColor Gray
        
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