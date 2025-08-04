function Get-MultiCloudDeploymentParameters {
    <#
    .SYNOPSIS
        Gets multi-cloud deployment parameters from user input.
    
    .DESCRIPTION
        Prompts the user for multi-cloud deployment parameters and returns them as a hashtable.
    
    .PARAMETER DeploymentType
        The type of multi-cloud deployment (multicloudinfrastructure, hybridcloudbridge, etc.).
    
    .PARAMETER Config
        The configuration object containing default values.
    
    .EXAMPLE
        Get-MultiCloudDeploymentParameters -DeploymentType "multicloudinfrastructure" -Config $config
    
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
        Write-ColorOutput "`nCollecting multi-cloud deployment parameters..." -ForegroundColor Cyan
        
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
            "multicloudinfrastructure" {
                $projectName = Read-Host "Multi-Cloud Project Name (default: $($config.env)-$($config.loc)-multicloud-$($config.project))"
                if ([string]::IsNullOrWhiteSpace($projectName)) {
                    $projectName = "$($config.env)-$($config.loc)-multicloud-$($config.project)"
                }
                
                $enableAzure = Read-Host "Enable Azure Deployment (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableAzure) -or $enableAzure -eq "y") {
                    $enableAzure = $true
                }
                else {
                    $enableAzure = $false
                }
                
                $enableAWS = Read-Host "Enable AWS Deployment (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableAWS) -or $enableAWS -eq "n") {
                    $enableAWS = $false
                }
                else {
                    $enableAWS = $true
                }
                
                $enableGCP = Read-Host "Enable Google Cloud Deployment (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableGCP) -or $enableGCP -eq "n") {
                    $enableGCP = $false
                }
                else {
                    $enableGCP = $true
                }
                
                $infrastructureType = Read-Host "Infrastructure Type (compute/storage/networking/all) (default: all)"
                if ([string]::IsNullOrWhiteSpace($infrastructureType)) {
                    $infrastructureType = "all"
                }
                
                $enableTerraform = Read-Host "Use Terraform for Infrastructure as Code (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableTerraform) -or $enableTerraform -eq "n") {
                    $enableTerraform = $false
                }
                else {
                    $enableTerraform = $true
                }
                
                $enableBicep = Read-Host "Use Bicep for Azure Infrastructure (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableBicep) -or $enableBicep -eq "y") {
                    $enableBicep = $true
                }
                else {
                    $enableBicep = $false
                }
                
                $enableCloudFormation = Read-Host "Use CloudFormation for AWS Infrastructure (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableCloudFormation) -or $enableCloudFormation -eq "n") {
                    $enableCloudFormation = $false
                }
                else {
                    $enableCloudFormation = $true
                }
                
                $enableKubernetes = Read-Host "Deploy Kubernetes Clusters (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableKubernetes) -or $enableKubernetes -eq "n") {
                    $enableKubernetes = $false
                }
                else {
                    $enableKubernetes = $true
                }
                
                $enableMonitoring = Read-Host "Enable Unified Monitoring (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableMonitoring) -or $enableMonitoring -eq "y") {
                    $enableMonitoring = $true
                }
                else {
                    $enableMonitoring = $false
                }
                
                $enableSecurity = Read-Host "Enable Unified Security Policies (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableSecurity) -or $enableSecurity -eq "y") {
                    $enableSecurity = $true
                }
                else {
                    $enableSecurity = $false
                }
                
                return @{
                    ResourceGroup        = $resourceGroup
                    Location             = $location
                    ProjectName          = $projectName
                    EnableAzure          = $enableAzure
                    EnableAWS            = $enableAWS
                    EnableGCP            = $enableGCP
                    InfrastructureType   = $infrastructureType
                    EnableTerraform      = $enableTerraform
                    EnableBicep          = $enableBicep
                    EnableCloudFormation = $enableCloudFormation
                    EnableKubernetes     = $enableKubernetes
                    EnableMonitoring     = $enableMonitoring
                    EnableSecurity       = $enableSecurity
                }
            }
            
            "hybridcloudbridge" {
                $projectName = Read-Host "Hybrid Cloud Project Name (default: $($config.env)-$($config.loc)-hybrid-$($config.project))"
                if ([string]::IsNullOrWhiteSpace($projectName)) {
                    $projectName = "$($config.env)-$($config.loc)-hybrid-$($config.project)"
                }
                
                $onPremisesNetwork = Read-Host "On-Premises Network CIDR (default: 192.168.0.0/16)"
                if ([string]::IsNullOrWhiteSpace($onPremisesNetwork)) {
                    $onPremisesNetwork = "192.168.0.0/16"
                }
                
                $enableVPNGateway = Read-Host "Enable VPN Gateway for Site-to-Site Connectivity (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableVPNGateway) -or $enableVPNGateway -eq "y") {
                    $enableVPNGateway = $true
                }
                else {
                    $enableVPNGateway = $false
                }
                
                $enableExpressRoute = Read-Host "Enable ExpressRoute for Dedicated Connectivity (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableExpressRoute) -or $enableExpressRoute -eq "n") {
                    $enableExpressRoute = $false
                }
                else {
                    $enableExpressRoute = $true
                }
                
                $enableAzureBastion = Read-Host "Enable Azure Bastion for Secure Access (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableAzureBastion) -or $enableAzureBastion -eq "y") {
                    $enableAzureBastion = $true
                }
                else {
                    $enableAzureBastion = $false
                }
                
                $enableHybridDNS = Read-Host "Enable Hybrid DNS Resolution (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableHybridDNS) -or $enableHybridDNS -eq "y") {
                    $enableHybridDNS = $true
                }
                else {
                    $enableHybridDNS = $false
                }
                
                $enableHybridMonitoring = Read-Host "Enable Hybrid Monitoring and Logging (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableHybridMonitoring) -or $enableHybridMonitoring -eq "y") {
                    $enableHybridMonitoring = $true
                }
                else {
                    $enableHybridMonitoring = $false
                }
                
                $enableHybridSecurity = Read-Host "Enable Hybrid Security Policies (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableHybridSecurity) -or $enableHybridSecurity -eq "y") {
                    $enableHybridSecurity = $true
                }
                else {
                    $enableHybridSecurity = $false
                }
                
                $enableHybridBackup = Read-Host "Enable Hybrid Backup Solutions (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableHybridBackup) -or $enableHybridBackup -eq "n") {
                    $enableHybridBackup = $false
                }
                else {
                    $enableHybridBackup = $true
                }
                
                $enableHybridDisasterRecovery = Read-Host "Enable Hybrid Disaster Recovery (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableHybridDisasterRecovery) -or $enableHybridDisasterRecovery -eq "n") {
                    $enableHybridDisasterRecovery = $false
                }
                else {
                    $enableHybridDisasterRecovery = $true
                }
                
                return @{
                    ResourceGroup                = $resourceGroup
                    Location                     = $location
                    ProjectName                  = $projectName
                    OnPremisesNetwork            = $onPremisesNetwork
                    EnableVPNGateway             = $enableVPNGateway
                    EnableExpressRoute           = $enableExpressRoute
                    EnableAzureBastion           = $enableAzureBastion
                    EnableHybridDNS              = $enableHybridDNS
                    EnableHybridMonitoring       = $enableHybridMonitoring
                    EnableHybridSecurity         = $enableHybridSecurity
                    EnableHybridBackup           = $enableHybridBackup
                    EnableHybridDisasterRecovery = $enableHybridDisasterRecovery
                }
            }
            
            default {
                Write-ColorOutput "Unsupported deployment type: $DeploymentType" -ForegroundColor Red
                return $null
            }
        }
    }
    catch {
        Write-ColorOutput "Error getting multi-cloud deployment parameters: $_" -ForegroundColor Red
        return $null
    }
} 