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
        
        # Helper function for consistent y/n input handling
        function Read-YesNoPrompt {
            param(
                [string]$Prompt,
                [bool]$DefaultValue
            )
            
            $defaultText = if ($DefaultValue) { "y" } else { "n" }
            $userInput = Read-Host "$Prompt (y/n) (default: $defaultText)"
            
            if ([string]::IsNullOrWhiteSpace($userInput)) {
                return $DefaultValue
            }
            else {
                return ($userInput -eq "y" -or $userInput -eq "yes")
            }
        }
        
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
                
                $enableAzure = Read-YesNoPrompt -Prompt "Enable Azure Deployment" -DefaultValue $true
                
                $enableAWS = Read-YesNoPrompt -Prompt "Enable AWS Deployment" -DefaultValue $false
                
                $enableGCP = Read-YesNoPrompt -Prompt "Enable Google Cloud Deployment" -DefaultValue $false
                
                $infrastructureType = Read-Host "Infrastructure Type (compute/storage/networking/all) (default: all)"
                if ([string]::IsNullOrWhiteSpace($infrastructureType)) {
                    $infrastructureType = "all"
                }
                else {
                    # Validate infrastructure type input against allowed values
                    $allowedInfrastructureTypes = @("compute", "storage", "networking", "all")
                    if ($infrastructureType -notin $allowedInfrastructureTypes) {
                        Write-ColorOutput "Invalid infrastructure type. Allowed values are: compute, storage, networking, all. Using default value: all" -ForegroundColor Yellow
                        $infrastructureType = "all"
                    }
                }
                
                $enableTerraform = Read-YesNoPrompt -Prompt "Use Terraform for Infrastructure as Code" -DefaultValue $false
                
                $enableBicep = Read-YesNoPrompt -Prompt "Use Bicep for Azure Infrastructure" -DefaultValue $true
                
                $enableCloudFormation = Read-YesNoPrompt -Prompt "Use CloudFormation for AWS Infrastructure" -DefaultValue $false
                
                $enableKubernetes = Read-YesNoPrompt -Prompt "Deploy Kubernetes Clusters" -DefaultValue $false
                
                $enableMonitoring = Read-YesNoPrompt -Prompt "Enable Unified Monitoring" -DefaultValue $true
                
                $enableSecurity = Read-YesNoPrompt -Prompt "Enable Unified Security Policies" -DefaultValue $true
                
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
                else {
                    # Validate CIDR input
                    try {
                        # Basic CIDR format validation
                        $cidrPattern = '^(\d{1,3}\.){3}\d{1,3}/\d{1,2}$'
                        if ($onPremisesNetwork -notmatch $cidrPattern) {
                            throw "Invalid CIDR format"
                        }
                        
                        # Parse CIDR components
                        $parts = $onPremisesNetwork.Split('/')
                        $ipString = $parts[0]
                        $subnetBits = [int]$parts[1]
                        
                        # Validate subnet mask range
                        if ($subnetBits -lt 0 -or $subnetBits -gt 32) {
                            throw "Invalid subnet mask"
                        }
                        
                        # Validate IP address format
                        $ipAddress = [System.Net.IPAddress]::Parse($ipString)
                        
                        Write-ColorOutput "Valid CIDR format: $onPremisesNetwork" -ForegroundColor Green
                    }
                    catch {
                        Write-ColorOutput "Invalid CIDR format. Expected format: x.x.x.x/y (e.g., 192.168.0.0/16). Using default value: 192.168.0.0/16" -ForegroundColor Yellow
                        $onPremisesNetwork = "192.168.0.0/16"
                    }
                }
                
                $enableVPNGateway = Read-YesNoPrompt -Prompt "Enable VPN Gateway for Site-to-Site Connectivity" -DefaultValue $true
                
                $enableExpressRoute = Read-YesNoPrompt -Prompt "Enable ExpressRoute for Dedicated Connectivity" -DefaultValue $false
                
                $enableAzureBastion = Read-YesNoPrompt -Prompt "Enable Azure Bastion for Secure Access" -DefaultValue $true
                
                $enableHybridDNS = Read-YesNoPrompt -Prompt "Enable Hybrid DNS Resolution" -DefaultValue $true
                
                $enableHybridMonitoring = Read-YesNoPrompt -Prompt "Enable Hybrid Monitoring and Logging" -DefaultValue $true
                
                $enableHybridSecurity = Read-YesNoPrompt -Prompt "Enable Hybrid Security Policies" -DefaultValue $true
                
                $enableHybridBackup = Read-YesNoPrompt -Prompt "Enable Hybrid Backup Solutions" -DefaultValue $false
                
                $enableHybridDisasterRecovery = Read-YesNoPrompt -Prompt "Enable Hybrid Disaster Recovery" -DefaultValue $false
                
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