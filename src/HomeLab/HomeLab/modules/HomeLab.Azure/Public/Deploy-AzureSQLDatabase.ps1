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
        try {
            $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
            if ($rgExists -ne "true") {
                Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
                az group create --name $ResourceGroup --location $Location
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create resource group '$ResourceGroup'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created resource group: $ResourceGroup" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "Resource group '$ResourceGroup' already exists" -ForegroundColor Green
            }
        }
        catch {
            Write-ColorOutput "Error with resource group operations: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to handle resource group '$ResourceGroup': $($_.Exception.Message)"
        }
        
        # Check if SQL Server exists
        try {
            $serverExists = az sql server show --name $ServerName --resource-group $ResourceGroup --output tsv 2>$null
            if (-not $serverExists) {
                Write-ColorOutput "Creating SQL Server: $ServerName" -ForegroundColor Yellow
                az sql server create `
                    --name $ServerName `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --admin-user $AdminUsername `
                    --admin-password $plainPassword
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create SQL Server '$ServerName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created SQL Server: $ServerName" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "SQL Server '$ServerName' already exists" -ForegroundColor Green
            }
        }
        catch {
            Write-ColorOutput "Error with SQL Server operations: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to handle SQL Server '$ServerName': $($_.Exception.Message)"
        }
        
        # Configure SQL Server firewall to allow Azure services
        Write-ColorOutput "Configuring SQL Server firewall..." -ForegroundColor Yellow
        try {
            az sql server firewall-rule create `
                --resource-group $ResourceGroup `
                --server $ServerName `
                --name "AllowAzureServices" `
                --start-ip-address "0.0.0.0" `
                --end-ip-address "0.0.0.0"
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to create firewall rule 'AllowAzureServices'. Exit code: $LASTEXITCODE"
            }
            
            Write-ColorOutput "Successfully configured SQL Server firewall" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error configuring SQL Server firewall: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to configure SQL Server firewall: $($_.Exception.Message)"
        }
        
        # Create SQL Database
        Write-ColorOutput "Creating SQL Database: $DatabaseName" -ForegroundColor Yellow
        try {
            az sql db create `
                --resource-group $ResourceGroup `
                --server $ServerName `
                --name $DatabaseName `
                --edition $PricingTier `
                --capacity $MaxSizeGB `
                --collation $Collation
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to create SQL Database '$DatabaseName'. Exit code: $LASTEXITCODE"
            }
            
            Write-ColorOutput "Successfully created SQL Database: $DatabaseName" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error creating SQL Database '$DatabaseName': $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to create SQL Database '$DatabaseName': $($_.Exception.Message)"
        }
        
        # Configure auditing if enabled
        if ($EnableAuditing) {
            Write-ColorOutput "Configuring database auditing..." -ForegroundColor Yellow
            try {
                $storageAccountName = Get-StorageAccountForAuditing -ResourceGroup $ResourceGroup -Location $Location
                
                az sql db audit-policy update `
                    --resource-group $ResourceGroup `
                    --server $ServerName `
                    --name $DatabaseName `
                    --state Enabled `
                    --storage-account $storageAccountName
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to configure database auditing. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully configured database auditing" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error configuring database auditing: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to configure database auditing: $($_.Exception.Message)"
            }
        }
        
        # Configure threat detection if enabled
        if ($EnableThreatDetection) {
            Write-ColorOutput "Configuring threat detection..." -ForegroundColor Yellow
            try {
                az sql db threat-policy update `
                    --resource-group $ResourceGroup `
                    --server $ServerName `
                    --name $DatabaseName `
                    --state Enabled
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to configure threat detection. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully configured threat detection" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error configuring threat detection: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to configure threat detection: $($_.Exception.Message)"
            }
        }
        
        # Helper function to mask sensitive connection strings
        function Get-MaskedConnectionString {
            param([string]$ConnectionString)
            if ([string]::IsNullOrEmpty($ConnectionString)) {
                return "[NOT SET]"
            }
            # Mask the password portion of the connection string
            $maskedString = $ConnectionString -replace 'Password=[^;]+', 'Password=***'
            return $maskedString
        }
        
        # Get connection string
        $connectionString = "Server=tcp:$ServerName.database.windows.net,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$AdminUsername;Password=$plainPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        
        # Display deployment summary
        Write-ColorOutput "`nAzure SQL Database deployment completed successfully!" -ForegroundColor Green
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "SQL Server: $ServerName.database.windows.net" -ForegroundColor Gray
        Write-ColorOutput "Database: $DatabaseName" -ForegroundColor Gray
        Write-ColorOutput "Admin Username: $AdminUsername" -ForegroundColor Gray
        Write-ColorOutput "Connection String: $(Get-MaskedConnectionString -ConnectionString $connectionString)" -ForegroundColor Gray
        
        # Security warning for sensitive data
        Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
        Write-ColorOutput "The returned object contains sensitive SQL Database connection strings." -ForegroundColor Yellow
        Write-ColorOutput "Please ensure this data is:" -ForegroundColor Yellow
        Write-ColorOutput "  • Not logged or written to files" -ForegroundColor Yellow
        Write-ColorOutput "  • Not committed to version control" -ForegroundColor Yellow
        Write-ColorOutput "  • Stored securely in production environments" -ForegroundColor Yellow
        Write-ColorOutput "  • Considered for Azure Key Vault integration" -ForegroundColor Yellow
        
        # Return deployment info (excluding sensitive password and masking connection string)
        return @{
            ResourceGroup    = $ResourceGroup
            ServerName       = $ServerName
            DatabaseName     = $DatabaseName
            ConnectionString = Get-MaskedConnectionString -ConnectionString $connectionString
            AdminUsername    = $AdminUsername
            # Note: AdminPassword is intentionally excluded for security
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
    
    .DESCRIPTION
        Creates a unique storage account name using robust identifier generation
        and ensures the account is created successfully with proper error handling.
    
    .PARAMETER ResourceGroup
        The resource group where the storage account will be created.
    
    .PARAMETER Location
        The Azure location for the storage account.
    
    .RETURNS
        The name of the created storage account.
    
    .EXAMPLE
        Get-StorageAccountForAuditing -ResourceGroup "my-rg" -Location "southafricanorth"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$Location
    )
    
    # Generate a unique storage account name with robust retry logic
    $maxAttempts = 15
    $attempt = 0
    $storageAccountName = $null
    
    do {
        $attempt++
        
        # Create a more robust unique identifier using timestamp and GUID
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $guidSegment = (New-Guid).ToString().Substring(0, 8)
        $randomSuffix = Get-Random -Minimum 100000 -Maximum 999999
        $baseName = "sqlaudit"
        
        # Combine elements for uniqueness
        $storageAccountName = "$baseName$timestamp$guidSegment$randomSuffix"
        
        # Ensure storage account name meets Azure requirements (3-24 chars, lowercase, numbers)
        if ($storageAccountName.Length -gt 24) {
            $storageAccountName = $storageAccountName.Substring(0, 24)
        }
        
        # Check if storage account exists
        try {
            $storageExists = az storage account show --name $storageAccountName --resource-group $ResourceGroup --output tsv 2>$null
            
            if ($storageExists) {
                Write-ColorOutput "Storage account $storageAccountName already exists, trying another name... (Attempt $attempt/$maxAttempts)" -ForegroundColor Yellow
                $storageAccountName = $null
            }
            else {
                Write-ColorOutput "Generated unique storage account name: $storageAccountName" -ForegroundColor Green
            }
        }
        catch {
            Write-ColorOutput "Error checking storage account existence: $($_.Exception.Message)" -ForegroundColor Red
            $storageAccountName = $null
        }
    } while (-not $storageAccountName -and $attempt -lt $maxAttempts)
    
    if (-not $storageAccountName) {
        throw "Failed to generate a unique storage account name after $maxAttempts attempts. Please try again or specify a custom storage account name."
    }
    
    # Create the storage account with error handling
    Write-ColorOutput "Creating storage account for auditing: $storageAccountName" -ForegroundColor Yellow
    try {
        az storage account create `
            --name $storageAccountName `
            --resource-group $ResourceGroup `
            --location $Location `
            --sku Standard_LRS `
            --kind StorageV2
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create storage account '$storageAccountName'. Exit code: $LASTEXITCODE"
        }
        
        Write-ColorOutput "Successfully created storage account for auditing: $storageAccountName" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error creating storage account '$storageAccountName': $($_.Exception.Message)" -ForegroundColor Red
        throw "Failed to create storage account for auditing: $($_.Exception.Message)"
    }
    
    return $storageAccountName
} 