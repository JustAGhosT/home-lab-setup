function Get-StorageDeploymentParameters {
    <#
    .SYNOPSIS
        Gets storage deployment parameters from user input.
    
    .DESCRIPTION
        Prompts the user for storage deployment parameters and returns them as a hashtable.
    
    .PARAMETER DeploymentType
        The type of storage deployment (azureblob, azurecdn, etc.).
    
    .PARAMETER Config
        The configuration object containing default values.
    
    .EXAMPLE
        Get-StorageDeploymentParameters -DeploymentType "azureblob" -Config $config
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DeploymentType,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )
    
    try {
        Write-ColorOutput "`nCollecting storage deployment parameters..." -ForegroundColor Cyan
        
        # Get basic parameters
        $resourceGroup = Read-Host "Resource Group Name (default: $($config.env)-$($config.loc)-rg-$($config.project))"
        if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
            $resourceGroup = "$($config.env)-$($config.loc)-rg-$($config.project)"
        }
        
        $location = Read-Host "Location (default: $($config.location))"
        if ([string]::IsNullOrWhiteSpace($location)) {
            $location = $config.location
        }
        
        switch ($DeploymentType) {
            "azureblob" {
                $storageAccountName = Read-Host "Storage Account Name (default: $($config.env)$($config.loc)storage$($config.project))"
                if ([string]::IsNullOrWhiteSpace($storageAccountName)) {
                    $storageAccountName = "$($config.env)$($config.loc)storage$($config.project)"
                }
                
                $containerNames = Read-Host "Container Names (comma-separated) (default: uploads,documents,images)"
                if ([string]::IsNullOrWhiteSpace($containerNames)) {
                    $containerNames = @("uploads", "documents", "images")
                }
                else {
                    $containerNames = $containerNames.Split(",") | ForEach-Object { $_.Trim() }
                }
                
                $accessLevel = Read-Host "Access Level (Private/Blob/Container) (default: Private)"
                if ([string]::IsNullOrWhiteSpace($accessLevel)) {
                    $accessLevel = "Private"
                }
                
                $sku = Read-Host "SKU (Standard_LRS/Standard_GRS/Standard_RAGRS/Premium_LRS) (default: Standard_LRS)"
                if ([string]::IsNullOrWhiteSpace($sku)) {
                    $sku = "Standard_LRS"
                }
                
                $enableStaticWebsite = Read-Host "Enable Static Website Hosting (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableStaticWebsite) -or $enableStaticWebsite -eq "n") {
                    $enableStaticWebsite = $false
                }
                else {
                    $enableStaticWebsite = $true
                }
                
                return @{
                    ResourceGroup       = $resourceGroup
                    Location            = $location
                    StorageAccountName  = $storageAccountName
                    ContainerNames      = $containerNames
                    AccessLevel         = $accessLevel
                    Sku                 = $sku
                    EnableStaticWebsite = $enableStaticWebsite
                }
            }
            
            "azurecdn" {
                $cdnProfileName = Read-Host "CDN Profile Name (default: $($config.env)-$($config.loc)-cdn-$($config.project))"
                if ([string]::IsNullOrWhiteSpace($cdnProfileName)) {
                    $cdnProfileName = "$($config.env)-$($config.loc)-cdn-$($config.project)"
                }
                
                $cdnEndpointName = Read-Host "CDN Endpoint Name (default: $($config.project)-cdn)"
                if ([string]::IsNullOrWhiteSpace($cdnEndpointName)) {
                    $cdnEndpointName = "$($config.project)-cdn"
                }
                
                $originHostName = Read-Host "Origin Host Name (e.g., mystorageaccount.blob.core.windows.net)"
                if ([string]::IsNullOrWhiteSpace($originHostName)) {
                    Write-ColorOutput "Origin host name is required!" -ForegroundColor Red
                    return $null
                }
                
                $originPath = Read-Host "Origin Path (default: /)"
                if ([string]::IsNullOrWhiteSpace($originPath)) {
                    $originPath = "/"
                }
                
                $sku = Read-Host "CDN SKU (Standard_Microsoft/Standard_Akamai/Standard_Verizon/Premium_Microsoft) (default: Standard_Microsoft)"
                if ([string]::IsNullOrWhiteSpace($sku)) {
                    $sku = "Standard_Microsoft"
                }
                
                $enableHttps = Read-Host "Enable HTTPS (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableHttps) -or $enableHttps -eq "y") {
                    $enableHttps = $true
                }
                else {
                    $enableHttps = $false
                }
                
                $enableCompression = Read-Host "Enable Compression (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableCompression) -or $enableCompression -eq "y") {
                    $enableCompression = $true
                }
                else {
                    $enableCompression = $false
                }
                
                return @{
                    ResourceGroup     = $resourceGroup
                    Location          = $location
                    CdnProfileName    = $cdnProfileName
                    CdnEndpointName   = $cdnEndpointName
                    OriginHostName    = $originHostName
                    OriginPath        = $originPath
                    Sku               = $sku
                    EnableHttps       = $enableHttps
                    EnableCompression = $enableCompression
                }
            }
            
            default {
                Write-ColorOutput "Unsupported deployment type: $DeploymentType" -ForegroundColor Red
                return $null
            }
        }
    }
    catch {
        Write-ColorOutput "Error getting storage deployment parameters: $_" -ForegroundColor Red
        return $null
    }
} 