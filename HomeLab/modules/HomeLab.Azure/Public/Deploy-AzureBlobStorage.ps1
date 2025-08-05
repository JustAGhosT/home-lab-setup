function Deploy-AzureBlobStorage {
    <#
    .SYNOPSIS
        Deploys Azure Blob Storage.
    
    .DESCRIPTION
        Deploys Azure Blob Storage with configurable parameters including storage account,
        containers, and access levels.
    
    .PARAMETER ResourceGroup
        The resource group name where the storage account will be deployed.
    
    .PARAMETER Location
        The Azure location for the deployment.
    
    .PARAMETER StorageAccountName
        The name of the storage account.
    
    .PARAMETER ContainerNames
        Array of container names to create.
    
    .PARAMETER AccessLevel
        The access level for containers (Private, Blob, Container).
    
    .PARAMETER Sku
        The storage account SKU (Standard_LRS, Standard_GRS, Premium_LRS, etc.).
    
    .PARAMETER EnableHttpsTrafficOnly
        Whether to enable HTTPS traffic only.
    
    .PARAMETER EnableHierarchicalNamespace
        Whether to enable hierarchical namespace (Data Lake Storage Gen2).
    
    .PARAMETER EnableStaticWebsite
        Whether to enable static website hosting.
    
    .PARAMETER IndexDocument
        The index document for static website hosting.
    
    .PARAMETER ErrorDocument
        The error document for static website hosting.
    
    .EXAMPLE
        Deploy-AzureBlobStorage -ResourceGroup "my-rg" -Location "southafricanorth" -StorageAccountName "mystorageaccount"
    
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
        [string]$StorageAccountName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ContainerNames = @("uploads", "documents", "images"),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Private", "Blob", "Container")]
        [string]$AccessLevel = "Private",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Standard_LRS", "Standard_GRS", "Standard_RAGRS", "Premium_LRS")]
        [string]$Sku = "Standard_LRS",
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableHttpsTrafficOnly = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableHierarchicalNamespace = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableStaticWebsite = $false,
        
        [Parameter(Mandatory = $false)]
        [string]$IndexDocument = "index.html",
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorDocument = "404.html"
    )
    
    try {
        Write-ColorOutput "Starting Azure Blob Storage deployment..." -ForegroundColor Cyan
        
        # Check if resource group exists
        $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
        if ($rgExists -ne "true") {
            Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
            az group create --name $ResourceGroup --location $Location
        }
        
        # Check if storage account exists
        $storageExists = az storage account show --name $StorageAccountName --resource-group $ResourceGroup --output tsv 2>$null
        if (-not $storageExists) {
            Write-ColorOutput "Creating storage account: $StorageAccountName" -ForegroundColor Yellow
            
            $createParams = @(
                "storage", "account", "create",
                "--name", $StorageAccountName,
                "--resource-group", $ResourceGroup,
                "--location", $Location,
                "--sku", $Sku,
                "--https-only", $EnableHttpsTrafficOnly.ToString().ToLower()
            )
            
            if ($EnableHierarchicalNamespace) {
                $createParams += "--enable-hierarchical-namespace"
            }
            
            az $createParams
        }
        
        # Get storage account keys
        Write-ColorOutput "Getting storage account keys..." -ForegroundColor Yellow
        try {
            $storageKey = az storage account keys list `
                --account-name $StorageAccountName `
                --resource-group $ResourceGroup `
                --query "[0].value" `
                --output tsv
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve storage account keys. Exit code: $LASTEXITCODE"
            }
            
            if ([string]::IsNullOrWhiteSpace($storageKey)) {
                throw "Storage account key is empty or null. Please check if the storage account exists and you have proper permissions."
            }
            
            Write-ColorOutput "Successfully retrieved storage account key" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving storage account keys: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve storage account keys for '$StorageAccountName': $($_.Exception.Message)"
        }
        
        # Create containers
        foreach ($containerName in $ContainerNames) {
            Write-ColorOutput "Creating container: $containerName" -ForegroundColor Yellow
            try {
                az storage container create `
                    --account-name $StorageAccountName `
                    --account-key $storageKey `
                    --name $containerName `
                    --public-access $AccessLevel.ToLower()
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create container '$containerName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created container: $containerName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating container '$containerName': $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create container '$containerName': $($_.Exception.Message)"
            }
        }
        
        # Enable static website hosting if requested
        if ($EnableStaticWebsite) {
            Write-ColorOutput "Enabling static website hosting..." -ForegroundColor Yellow
            try {
                az storage blob service-properties update `
                    --account-name $StorageAccountName `
                    --account-key $storageKey `
                    --static-website `
                    --index-document $IndexDocument `
                    --404-document $ErrorDocument
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to enable static website hosting. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully enabled static website hosting" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error enabling static website hosting: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to enable static website hosting: $($_.Exception.Message)"
            }
        }
        
        # Get connection string
        try {
            $connectionString = az storage account show-connection-string `
                --name $StorageAccountName `
                --resource-group $ResourceGroup `
                --query "connectionString" `
                --output tsv
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve connection string. Exit code: $LASTEXITCODE"
            }
            
            if ([string]::IsNullOrWhiteSpace($connectionString)) {
                throw "Connection string is empty or null. Please check if the storage account exists and you have proper permissions."
            }
            
            Write-ColorOutput "Successfully retrieved connection string" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving connection string: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve connection string for '$StorageAccountName': $($_.Exception.Message)"
        }
        
        # Get storage account URL
        $storageUrl = "https://$StorageAccountName.blob.core.windows.net"
        
        # Get static website URL if enabled
        $staticWebsiteUrl = $null
        if ($EnableStaticWebsite) {
            $staticWebsiteUrl = "https://$StorageAccountName.z13.web.core.windows.net"
        }
        
        # Display deployment summary
        Write-ColorOutput "`nAzure Blob Storage deployment completed successfully!" -ForegroundColor Green
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "Storage Account: $StorageAccountName" -ForegroundColor Gray
        Write-ColorOutput "SKU: $Sku" -ForegroundColor Gray
        Write-ColorOutput "Containers: $($ContainerNames -join ', ')" -ForegroundColor Gray
        Write-ColorOutput "Access Level: $AccessLevel" -ForegroundColor Gray
        Write-ColorOutput "Storage URL: $storageUrl" -ForegroundColor Gray
        # Connection string intentionally omitted for security - available in return object
        
        if ($EnableStaticWebsite) {
            Write-ColorOutput "Static Website URL: $staticWebsiteUrl" -ForegroundColor Gray
        }
        
        # Security warning for sensitive data
        Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
        Write-ColorOutput "The returned object contains sensitive connection strings and storage keys." -ForegroundColor Yellow
        Write-ColorOutput "Please ensure this data is:" -ForegroundColor Yellow
        Write-ColorOutput "  • Not logged or written to files" -ForegroundColor Yellow
        Write-ColorOutput "  • Not committed to version control" -ForegroundColor Yellow
        Write-ColorOutput "  • Stored securely in production environments" -ForegroundColor Yellow
        Write-ColorOutput "  • Considered for Azure Key Vault integration" -ForegroundColor Yellow
        
        # Return deployment info
        return @{
            ResourceGroup      = $ResourceGroup
            StorageAccountName = $StorageAccountName
            ContainerNames     = $ContainerNames
            AccessLevel        = $AccessLevel
            Sku                = $Sku
            StorageUrl         = $storageUrl
            ConnectionString   = $connectionString
            StaticWebsiteUrl   = $staticWebsiteUrl
            StorageKey         = $storageKey
        }
    }
    catch {
        Write-ColorOutput "Error deploying Azure Blob Storage: $_" -ForegroundColor Red
        throw
    }
} 