function Deploy-AzureSQLDatabase {
    <#
    .SYNOPSIS
        Deploys an Azure SQL Database.
    
    .DESCRIPTION
        Deploys an Azure SQL Database with configurable parameters including server,
        database name, pricing tier, and connection settings.
    
    .PARAMETER ResourceGroup
        The resource group name where the SQL Database will be deployed.
    
    .PARAMETER Location
        The Azure location for the deployment.
    
    .PARAMETER ServerName
        The name of the SQL Server (will be created if it doesn't exist).
    
    .PARAMETER DatabaseName
        The name of the SQL Database.
    
    .PARAMETER AdminUsername
        The SQL Server administrator username.
    
    .PARAMETER AdminPassword
        The SQL Server administrator password.
    
    .PARAMETER PricingTier
        The pricing tier for the SQL Database (Basic, Standard, Premium).
    
    .PARAMETER MaxSizeGB
        The maximum size of the database in GB.
    
    .PARAMETER Collation
        The database collation.
    
    .PARAMETER EnableGeoReplication
        Whether to enable geo-replication.
    
    .PARAMETER EnableAuditing
        Whether to enable auditing.
    
    .PARAMETER EnableThreatDetection
        Whether to enable threat detection.
    
    .EXAMPLE
        Deploy-AzureSQLDatabase -ResourceGroup "my-rg" -Location "southafricanorth" -ServerName "my-sql-server" -DatabaseName "my-database"
    
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
        [string]$ServerName,
        
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        
        [Parameter(Mandatory = $false)]
        [string]$AdminUsername = "sqladmin",
        
        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$AdminPassword,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Standard", "Premium")]
        [string]$PricingTier = "Standard",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxSizeGB = 10,
        
        [Parameter(Mandatory = $false)]
        [string]$Collation = "SQL_Latin1_General_CP1_CI_AS",
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableGeoReplication = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableAuditing = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableThreatDetection = $true
    )
    
    try {
        Write-ColorOutput "Starting Azure SQL Database deployment..." -ForegroundColor Cyan
        
        # Convert SecureString to plain text if provided, or generate password
        if ($AdminPassword) {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
            $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            # Free the allocated BSTR memory to prevent memory leaks
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
        else {
            $plainPassword = [System.Web.Security.Membership]::GeneratePassword(16, 3)
            Write-ColorOutput "Generated admin password: $plainPassword" -ForegroundColor Yellow
        }
        
        # Check if resource group exists
        $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
        if ($rgExists -ne "true") {
            Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
            az group create --name $ResourceGroup --location $Location
        }
        
        # Check if SQL Server exists
        $serverExists = az sql server show --name $ServerName --resource-group $ResourceGroup --output tsv 2>$null
        if (-not $serverExists) {
            Write-ColorOutput "Creating SQL Server: $ServerName" -ForegroundColor Yellow
            az sql server create `
                --name $ServerName `
                --resource-group $ResourceGroup `
                --location $Location `
                --admin-user $AdminUsername `
                --admin-password $plainPassword
        }
        
        # Configure SQL Server firewall to allow Azure services
        Write-ColorOutput "Configuring SQL Server firewall..." -ForegroundColor Yellow
        az sql server firewall-rule create `
            --resource-group $ResourceGroup `
            --server $ServerName `
            --name "AllowAzureServices" `
            --start-ip-address "0.0.0.0" `
            --end-ip-address "0.0.0.0"
        
        # Create SQL Database
        Write-ColorOutput "Creating SQL Database: $DatabaseName" -ForegroundColor Yellow
        az sql db create `
            --resource-group $ResourceGroup `
            --server $ServerName `
            --name $DatabaseName `
            --edition $PricingTier `
            --capacity $MaxSizeGB `
            --collation $Collation
        
        # Configure auditing if enabled
        if ($EnableAuditing) {
            Write-ColorOutput "Configuring database auditing..." -ForegroundColor Yellow
            az sql db audit-policy update `
                --resource-group $ResourceGroup `
                --server $ServerName `
                --name $DatabaseName `
                --state Enabled `
                --storage-account (Get-StorageAccountForAuditing -ResourceGroup $ResourceGroup -Location $Location)
        }
        
        # Configure threat detection if enabled
        if ($EnableThreatDetection) {
            Write-ColorOutput "Configuring threat detection..." -ForegroundColor Yellow
            az sql db threat-policy update `
                --resource-group $ResourceGroup `
                --server $ServerName `
                --name $DatabaseName `
                --state Enabled
        }
        
        # Get connection string
        $connectionString = "Server=tcp:$ServerName.database.windows.net,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$AdminUsername;Password=$plainPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        
        # Display deployment summary
        Write-ColorOutput "`nAzure SQL Database deployment completed successfully!" -ForegroundColor Green
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "SQL Server: $ServerName.database.windows.net" -ForegroundColor Gray
        Write-ColorOutput "Database: $DatabaseName" -ForegroundColor Gray
        Write-ColorOutput "Admin Username: $AdminUsername" -ForegroundColor Gray
        Write-ColorOutput "Connection String: $connectionString" -ForegroundColor Gray
        
        # Return deployment info (excluding sensitive password)
        return @{
            ResourceGroup = $ResourceGroup
            ServerName = $ServerName
            DatabaseName = $DatabaseName
            ConnectionString = $connectionString
            AdminUsername = $AdminUsername
        }
    }
    catch {
        Write-ColorOutput "Error deploying Azure SQL Database: $_" -ForegroundColor Red
        throw
    }
}

function Get-StorageAccountForAuditing {
    <#
    .SYNOPSIS
        Gets or creates a storage account for SQL Database auditing.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$Location
    )
    
    # Generate a unique storage account name with retry logic
    $maxAttempts = 10
    $attempt = 0
    $storageAccountName = $null
    
    do {
        $attempt++
        $randomSuffix = Get-Random -Minimum 1000 -Maximum 9999
        $storageAccountName = "sqlaudit$randomSuffix"
        
        # Check if storage account exists
        $storageExists = az storage account show --name $storageAccountName --resource-group $ResourceGroup --output tsv 2>$null
        
        if ($storageExists) {
            Write-ColorOutput "Storage account $storageAccountName already exists, trying another name..." -ForegroundColor Yellow
            $storageAccountName = $null
        }
    } while (-not $storageAccountName -and $attempt -lt $maxAttempts)
    
    if (-not $storageAccountName) {
        throw "Failed to generate a unique storage account name after $maxAttempts attempts"
    }
    
    # Create the storage account if it doesn't exist
    Write-ColorOutput "Creating storage account for auditing: $storageAccountName" -ForegroundColor Yellow
    az storage account create `
        --name $storageAccountName `
        --resource-group $ResourceGroup `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2
    
    return $storageAccountName
} 