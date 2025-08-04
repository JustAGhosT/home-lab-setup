function Configure-CDNEndpoints {
    <#
    .SYNOPSIS
        Configures CDN endpoints and settings.
    
    .DESCRIPTION
        Configures CDN endpoints and settings for CDN deployments,
        including updating application configuration files.
    
    .PARAMETER ResourceGroup
        The resource group name.
    
    .PARAMETER CdnProfileName
        The CDN profile name.
    
    .PARAMETER CdnEndpointName
        The CDN endpoint name.
    
    .PARAMETER CdnUrl
        The CDN URL.
    
    .PARAMETER OriginHostName
        The origin host name.
    
    .PARAMETER ProjectPath
        The path to the project to configure.
    
    .EXAMPLE
        Configure-CDNEndpoints -ResourceGroup "my-rg" -CdnProfileName "my-cdn-profile" -CdnEndpointName "my-cdn-endpoint"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$CdnProfileName,
        
        [Parameter(Mandatory = $true)]
        [string]$CdnEndpointName,
        
        [Parameter(Mandatory = $false)]
        [string]$CdnUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$OriginHostName,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )
    
    try {
        Write-ColorOutput "Configuring CDN endpoints..." -ForegroundColor Cyan
        
        # Get CDN URL if not provided
        if (-not $CdnUrl) {
            $CdnUrl = "https://$CdnEndpointName.azureedge.net"
        }
        
        # Display connection information
        Write-ColorOutput "`nCDN Endpoint Information:" -ForegroundColor Green
        Write-ColorOutput "CDN Profile: $CdnProfileName" -ForegroundColor Gray
        Write-ColorOutput "CDN Endpoint: $CdnEndpointName" -ForegroundColor Gray
        Write-ColorOutput "CDN URL: $CdnUrl" -ForegroundColor Gray
        if ($OriginHostName) {
            Write-ColorOutput "Origin: $OriginHostName" -ForegroundColor Gray
        }
        
        # Update project configuration files if project path is provided
        if ($ProjectPath -and (Test-Path -Path $ProjectPath)) {
            Write-ColorOutput "`nUpdating project configuration files..." -ForegroundColor Yellow
            
            # Update appsettings.json for .NET projects
            $appSettingsPath = Join-Path -Path $ProjectPath -ChildPath "appsettings.json"
            if (Test-Path -Path $appSettingsPath) {
                Write-ColorOutput "Updating appsettings.json..." -ForegroundColor Gray
                try {
                    $appSettings = Get-Content -Path $appSettingsPath | ConvertFrom-Json
                    
                    if (-not $appSettings.CDN) {
                        $appSettings | Add-Member -MemberType NoteProperty -Name "CDN" -Value @{}
                    }
                    
                    $appSettings.CDN.ProfileName = $CdnProfileName
                    $appSettings.CDN.EndpointName = $CdnEndpointName
                    $appSettings.CDN.Url = $CdnUrl
                    $appSettings.CDN.OriginHostName = $OriginHostName
                    
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
                    
                    $packageJson.config.cdnProfileName = $CdnProfileName
                    $packageJson.config.cdnEndpointName = $CdnEndpointName
                    $packageJson.config.cdnUrl = $CdnUrl
                    $packageJson.config.cdnOriginHostName = $OriginHostName
                    
                    $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath
                    Write-ColorOutput "Updated package.json" -ForegroundColor Green
                }
                catch {
                    Write-ColorOutput "Error updating package.json: $($_.Exception.Message)" -ForegroundColor Red
                    throw "Failed to update package.json: $($_.Exception.Message)"
                }
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            @"
# Azure CDN Configuration
AZURE_CDN_PROFILE_NAME=$CdnProfileName
AZURE_CDN_ENDPOINT_NAME=$CdnEndpointName
AZURE_CDN_URL=$CdnUrl
AZURE_CDN_ORIGIN_HOST_NAME=$OriginHostName
"@ | Set-Content -Path $envPath
            Write-ColorOutput "Created .env file" -ForegroundColor Green
        }
        
        # Save connection information to a configuration file
        $configPath = Join-Path -Path $env:USERPROFILE -ChildPath ".homelab\cdn-connections.json"
        $configDir = Split-Path -Path $configPath -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $connectionConfig = @{
            ResourceGroup   = $ResourceGroup
            CdnProfileName  = $CdnProfileName
            CdnEndpointName = $CdnEndpointName
            CdnUrl          = $CdnUrl
            OriginHostName  = $OriginHostName
            CreatedAt       = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        try {
            $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath -ErrorAction Stop
            Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error saving connection configuration: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to save connection configuration: $($_.Exception.Message)"
        }
        
        Write-ColorOutput "`nCDN endpoint configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring CDN endpoints: $_" -ForegroundColor Red
        throw
    }
} 