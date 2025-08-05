function Deploy-AzureCDN {
    <#
    .SYNOPSIS
        Deploys Azure CDN.
    
    .DESCRIPTION
        Deploys Azure CDN with configurable parameters including profile, endpoints,
        and origin settings.
    
    .PARAMETER ResourceGroup
        The resource group name where the CDN will be deployed.
    
    .PARAMETER Location
        The Azure location for the deployment.
    
    .PARAMETER CdnProfileName
        The name of the CDN profile.
    
    .PARAMETER CdnEndpointName
        The name of the CDN endpoint.
    
    .PARAMETER OriginHostName
        The hostname of the origin (e.g., storage account, web app).
    
    .PARAMETER OriginHostHeader
        The host header for the origin.
    
    .PARAMETER OriginPath
        The path on the origin to serve content from.
    
    .PARAMETER Sku
        The CDN SKU (Standard_Microsoft, Standard_Akamai, Standard_Verizon, Premium_Microsoft).
    
    .PARAMETER EnableHttps
        Whether to enable HTTPS.
    
    .PARAMETER EnableCompression
        Whether to enable compression.
    
    .PARAMETER EnableQueryStringCaching
        Whether to enable query string caching.
    
    .PARAMETER CacheRules
        Array of cache rules to apply.
    
    .EXAMPLE
        Deploy-AzureCDN -ResourceGroup "my-rg" -Location "southafricanorth" -CdnProfileName "my-cdn-profile" -OriginHostName "mystorageaccount.blob.core.windows.net"
    
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
        [string]$CdnProfileName,
        
        [Parameter(Mandatory = $true)]
        [string]$CdnEndpointName,
        
        [Parameter(Mandatory = $true)]
        [string]$OriginHostName,
        
        [Parameter(Mandatory = $false)]
        [string]$OriginHostHeader,
        
        [Parameter(Mandatory = $false)]
        [string]$OriginPath = "/",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Standard_Microsoft", "Standard_Akamai", "Standard_Verizon", "Premium_Microsoft")]
        [string]$Sku = "Standard_Microsoft",
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableHttps = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableCompression = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableQueryStringCaching = $false,
        
        [Parameter(Mandatory = $false)]
        [hashtable[]]$CacheRules = @()
    )
    
    try {
        Write-ColorOutput "Starting Azure CDN deployment..." -ForegroundColor Cyan
        
        # Check if resource group exists
        $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
        if ($rgExists -ne "true") {
            Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
            az group create --name $ResourceGroup --location $Location
        }
        
        # Check if CDN profile exists
        $profileExists = az cdn profile show --name $CdnProfileName --resource-group $ResourceGroup --output tsv 2>$null
        if (-not $profileExists) {
            Write-ColorOutput "Creating CDN profile: $CdnProfileName" -ForegroundColor Yellow
            az cdn profile create `
                --name $CdnProfileName `
                --resource-group $ResourceGroup `
                --location $Location `
                --sku $Sku
        }
        
        # Check if CDN endpoint exists
        try {
            $endpointExists = az cdn endpoint show --name $CdnEndpointName --profile-name $CdnProfileName --resource-group $ResourceGroup --output tsv 2>$null
            if ($LASTEXITCODE -ne 0) {
                $endpointExists = $null
            }
        }
        catch {
            $endpointExists = $null
        }
        
        if (-not $endpointExists) {
            Write-ColorOutput "Creating CDN endpoint: $CdnEndpointName" -ForegroundColor Yellow
            
            $createParams = @(
                "cdn", "endpoint", "create",
                "--name", $CdnEndpointName,
                "--profile-name", $CdnProfileName,
                "--resource-group", $ResourceGroup,
                "--origin", $OriginHostName,
                "--origin-host-header", ($OriginHostHeader ?? $OriginHostName),
                "--origin-path", $OriginPath
            )
            
            if ($EnableCompression) {
                $createParams += "--enable-compression"
            }
            
            az $createParams
        }
        
        # Configure HTTPS if enabled
        if ($EnableHttps) {
            Write-ColorOutput "Configuring HTTPS..." -ForegroundColor Yellow
            az cdn endpoint update `
                --name $CdnEndpointName `
                --profile-name $CdnProfileName `
                --resource-group $ResourceGroup `
                --https-only
        }
        
        # Configure query string caching
        if ($EnableQueryStringCaching) {
            Write-ColorOutput "Configuring query string caching..." -ForegroundColor Yellow
            az cdn endpoint update `
                --name $CdnEndpointName `
                --profile-name $CdnProfileName `
                --resource-group $ResourceGroup `
                --query-string-caching "UseQueryString"
        }
        
        # Apply cache rules if specified
        if ($CacheRules.Count -gt 0) {
            Write-ColorOutput "Applying cache rules..." -ForegroundColor Yellow
            foreach ($rule in $CacheRules) {
                try {
                    az cdn endpoint rule add `
                        --name $CdnEndpointName `
                        --profile-name $CdnProfileName `
                        --resource-group $ResourceGroup `
                        --rule-name $rule.Name `
                        --order $rule.Order `
                        --action-name $rule.Action `
                        --match-variable $rule.MatchVariable `
                        --operator $rule.Operator `
                        --match-values $rule.MatchValues
                    
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to add cache rule '$($rule.Name)'. Exit code: $LASTEXITCODE"
                    }
                    
                    Write-ColorOutput "Successfully added cache rule: $($rule.Name)" -ForegroundColor Green
                }
                catch {
                    Write-ColorOutput "Error adding cache rule '$($rule.Name)': $($_.Exception.Message)" -ForegroundColor Red
                    throw "Failed to add cache rule '$($rule.Name)': $($_.Exception.Message)"
                }
            }
        }
        
        # Get CDN endpoint URL
        $cdnUrl = "https://$CdnEndpointName.azureedge.net"
        
        # Get CDN endpoint details
        $endpointDetails = az cdn endpoint show `
            --name $CdnEndpointName `
            --profile-name $CdnProfileName `
            --resource-group $ResourceGroup `
            --output json | ConvertFrom-Json
        
        # Display deployment summary
        Write-ColorOutput "`nAzure CDN deployment completed successfully!" -ForegroundColor Green
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "CDN Profile: $CdnProfileName" -ForegroundColor Gray
        Write-ColorOutput "CDN Endpoint: $CdnEndpointName" -ForegroundColor Gray
        Write-ColorOutput "Origin: $OriginHostName" -ForegroundColor Gray
        Write-ColorOutput "CDN URL: $cdnUrl" -ForegroundColor Gray
        Write-ColorOutput "SKU: $Sku" -ForegroundColor Gray
        Write-ColorOutput "HTTPS Enabled: $EnableHttps" -ForegroundColor Gray
        Write-ColorOutput "Compression Enabled: $EnableCompression" -ForegroundColor Gray
        
        # Return deployment info
        return @{
            ResourceGroup     = $ResourceGroup
            CdnProfileName    = $CdnProfileName
            CdnEndpointName   = $CdnEndpointName
            OriginHostName    = $OriginHostName
            OriginPath        = $OriginPath
            CdnUrl            = $cdnUrl
            Sku               = $Sku
            EnableHttps       = $EnableHttps
            EnableCompression = $EnableCompression
            EndpointDetails   = $endpointDetails
        }
    }
    catch {
        Write-ColorOutput "Error deploying Azure CDN: $_" -ForegroundColor Red
        throw
    }
} 