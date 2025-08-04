function Get-DatabaseDeploymentParameters {
    <#
    .SYNOPSIS
        Gets database deployment parameters from user input.
    
    .DESCRIPTION
        Prompts the user for database deployment parameters and returns them as a hashtable.
    
    .PARAMETER DeploymentType
        The type of database deployment (azuresql, azurecosmos, etc.).
    
    .PARAMETER Config
        The configuration object containing default values.
    
    .EXAMPLE
        Get-DatabaseDeploymentParameters -DeploymentType "azuresql" -Config $config
    
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
        Write-ColorOutput "`nCollecting database deployment parameters..." -ForegroundColor Cyan
        
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
            "azuresql" {
                $serverName = Read-Host "SQL Server Name (default: $($config.env)-$($config.loc)-sql-$($config.project))"
                if ([string]::IsNullOrWhiteSpace($serverName)) {
                    $serverName = "$($config.env)-$($config.loc)-sql-$($config.project)"
                }
                
                $databaseName = Read-Host "Database Name (default: $($config.project)db)"
                if ([string]::IsNullOrWhiteSpace($databaseName)) {
                    $databaseName = "$($config.project)db"
                }
                
                $adminUsername = Read-Host "Admin Username (default: sqladmin)"
                if ([string]::IsNullOrWhiteSpace($adminUsername)) {
                    $adminUsername = "sqladmin"
                }
                
                $adminPassword = Read-Host "Admin Password (leave empty to generate)" -AsSecureString
                $adminPasswordPlain = if ($adminPassword.Length -eq 0) { $null } else { [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword)) }
                
                $pricingTier = Read-Host "Pricing Tier (Basic/Standard/Premium) (default: Standard)"
                if ([string]::IsNullOrWhiteSpace($pricingTier)) {
                    $pricingTier = "Standard"
                }
                
                $maxSizeGB = Read-Host "Max Size (GB) (default: 10)"
                if ([string]::IsNullOrWhiteSpace($maxSizeGB)) {
                    $maxSizeGB = 10
                }
                else {
                    $maxSizeGB = [int]$maxSizeGB
                }
                
                $enableAuditing = Read-Host "Enable Auditing (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableAuditing) -or $enableAuditing -eq "y") {
                    $enableAuditing = $true
                }
                else {
                    $enableAuditing = $false
                }
                
                $enableThreatDetection = Read-Host "Enable Threat Detection (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableThreatDetection) -or $enableThreatDetection -eq "y") {
                    $enableThreatDetection = $true
                }
                else {
                    $enableThreatDetection = $false
                }
                
                return @{
                    ResourceGroup         = $resourceGroup
                    Location              = $location
                    ServerName            = $serverName
                    DatabaseName          = $databaseName
                    AdminUsername         = $adminUsername
                    AdminPassword         = $adminPasswordPlain
                    PricingTier           = $pricingTier
                    MaxSizeGB             = $maxSizeGB
                    EnableAuditing        = $enableAuditing
                    EnableThreatDetection = $enableThreatDetection
                }
            }
            
            "azurecosmos" {
                $accountName = Read-Host "Cosmos DB Account Name (default: $($config.env)-$($config.loc)-cosmos-$($config.project))"
                if ([string]::IsNullOrWhiteSpace($accountName)) {
                    $accountName = "$($config.env)-$($config.loc)-cosmos-$($config.project)"
                }
                
                $apiType = Read-Host "API Type (SQL/MongoDB/Cassandra/Gremlin/Table) (default: SQL)"
                if ([string]::IsNullOrWhiteSpace($apiType)) {
                    $apiType = "SQL"
                }
                
                $databaseName = Read-Host "Database Name (default: $($config.project)db)"
                if ([string]::IsNullOrWhiteSpace($databaseName)) {
                    $databaseName = "$($config.project)db"
                }
                
                $containerName = Read-Host "Container Name (default: items)"
                if ([string]::IsNullOrWhiteSpace($containerName)) {
                    $containerName = "items"
                }
                
                $consistencyLevel = Read-Host "Consistency Level (Eventual/ConsistentPrefix/Session/BoundedStaleness/Strong) (default: Session)"
                if ([string]::IsNullOrWhiteSpace($consistencyLevel)) {
                    $consistencyLevel = "Session"
                }
                
                $throughput = Read-Host "Throughput (RU/s) (default: 400)"
                if ([string]::IsNullOrWhiteSpace($throughput)) {
                    $throughput = 400
                }
                else {
                    $throughput = [int]$throughput
                }
                
                $enableMultiRegion = Read-Host "Enable Multi-Region (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableMultiRegion) -or $enableMultiRegion -eq "n") {
                    $enableMultiRegion = $false
                }
                else {
                    $enableMultiRegion = $true
                }
                
                return @{
                    ResourceGroup     = $resourceGroup
                    Location          = $location
                    AccountName       = $accountName
                    ApiType           = $apiType
                    DatabaseName      = $databaseName
                    ContainerName     = $containerName
                    ConsistencyLevel  = $consistencyLevel
                    Throughput        = $throughput
                    EnableMultiRegion = $enableMultiRegion
                }
            }
            
            default {
                Write-ColorOutput "Unsupported deployment type: $DeploymentType" -ForegroundColor Red
                return $null
            }
        }
    }
    catch {
        Write-ColorOutput "Error getting database deployment parameters: $_" -ForegroundColor Red
        return $null
    }
} 