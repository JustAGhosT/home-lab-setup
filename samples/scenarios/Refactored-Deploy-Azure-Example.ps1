# Refactored Deploy-Azure.ps1 - Enterprise Grade Example
# Demonstrates proper PowerShell patterns and fixes all quality issues

<#
.SYNOPSIS
    Deploys Azure infrastructure with enterprise-grade reliability and security
.DESCRIPTION
    This refactored script demonstrates proper PowerShell patterns including:
    - Enterprise logging framework instead of Write-Host
    - Comprehensive error handling and validation
    - ShouldProcess support for safe automation
    - Secure credential management
    - Parameter validation and documentation
    - Performance monitoring and metrics
    
.PARAMETER ResourceGroupName
    Name of the Azure resource group to create or use
.PARAMETER Location
    Azure region for resource deployment
.PARAMETER ProjectName
    Project identifier used for resource naming
.PARAMETER EnableMonitoring
    Whether to enable Azure Monitor and Log Analytics
.PARAMETER EnableBackup
    Whether to enable Azure Backup for critical resources
.PARAMETER Credential
    Azure credential object for authentication
.PARAMETER SubscriptionId
    Azure subscription ID to use for deployment
.PARAMETER WhatIf
    Shows what would happen if the cmdlet runs
.PARAMETER Confirm
    Prompts for confirmation before proceeding
    
.EXAMPLE
    Deploy-AzureInfrastructure -ResourceGroupName "my-rg" -Location "East US" -ProjectName "HomeLab"
    
.EXAMPLE
    Deploy-AzureInfrastructure -ResourceGroupName "prod-rg" -Location "West US 2" -EnableMonitoring -EnableBackup -Confirm:$false
    
.NOTES
    Author: Enterprise PowerShell Team
    Version: 2.0.0
    Date: 2025-01-27
    Requires: Az PowerShell module, Enterprise Logging Framework
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[a-zA-Z0-9-_]+$')]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('East US', 'West US', 'West US 2', 'Central US', 'North Central US', 'South Central US', 'East US 2', 'West Europe', 'North Europe')]
    [string]$Location,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[a-zA-Z0-9-_]+$')]
    [string]$ProjectName,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableMonitoring,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableBackup,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]$Credential,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')]
    [string]$SubscriptionId
)

#region Script Initialization

# Import enterprise logging framework
try {
    Import-Module "$PSScriptRoot\Enterprise-Logging-Framework.ps1" -Force
    Write-InfoLog -Message "Enterprise logging framework loaded successfully" -Category 'Initialization'
}
catch {
    throw "Failed to load enterprise logging framework: $($_.Exception.Message)"
}

# Initialize logging with project-specific configuration
$logPath = Join-Path $env:TEMP "HomeLab\Azure\$ProjectName"
Initialize-EnterpriseLogging -LogPath $logPath -LogLevel Info -EnableEventLog:$true

# Script-level variables
$script:DeploymentStartTime = Get-Date
$script:DeploymentMetrics = @{
    'ResourcesCreated' = 0
    'ResourcesUpdated' = 0
    'Errors'           = 0
    'Warnings'         = 0
    'Duration'         = $null
}

# Log deployment start
Write-InfoLog -Message "Azure infrastructure deployment started" -Category 'Deployment' -Properties @{
    'ResourceGroup'    = $ResourceGroupName
    'Location'         = $Location
    'Project'          = $ProjectName
    'EnableMonitoring' = $EnableMonitoring
    'EnableBackup'     = $EnableBackup
}

#endregion

#region Azure Authentication and Validation

<#
.SYNOPSIS
    Validates Azure authentication and subscription context
#>
function Test-AzureAuthentication {
    [CmdletBinding()]
    param()
    
    try {
        Write-InfoLog -Message "Validating Azure authentication..." -Category 'Authentication'
        
        # Check if already authenticated
        $context = Get-AzContext -ErrorAction SilentlyContinue
        if ($context) {
            Write-SuccessLog -Message "Already authenticated as: $($context.Account.Id)" -Category 'Authentication'
            
            # Set subscription if specified
            if ($SubscriptionId -and $context.Subscription.Id -ne $SubscriptionId) {
                if ($PSCmdlet.ShouldProcess($SubscriptionId, "Set Azure subscription context")) {
                    Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
                    Write-SuccessLog -Message "Subscription context set to: $SubscriptionId" -Category 'Authentication'
                }
            }
            return $true
        }
        
        # Authenticate if not already logged in
        if ($Credential) {
            Write-InfoLog -Message "Authenticating with provided credentials..." -Category 'Authentication'
            Connect-AzAccount -Credential $Credential -ErrorAction Stop
        }
        else {
            Write-InfoLog -Message "Authenticating interactively..." -Category 'Authentication'
            Connect-AzAccount -ErrorAction Stop
        }
        
        Write-SuccessLog -Message "Azure authentication successful" -Category 'Authentication'
        return $true
    }
    catch [System.Management.Automation.AuthenticationException] {
        Write-ErrorLog -Message "Authentication failed: Invalid credentials" -Category 'Authentication'
        throw "Azure authentication failed. Please check your credentials and try again."
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-ErrorLog -Message "Azure PowerShell module not found" -Category 'Authentication'
        throw "Az PowerShell module is required. Install with: Install-Module -Name Az"
    }
    catch {
        Write-ErrorLog -Message "Unexpected authentication error: $($_.Exception.Message)" -Category 'Authentication'
        throw "Authentication failed: $($_.Exception.Message)"
    }
}

#endregion

#region Resource Group Management

<#
.SYNOPSIS
    Creates or validates the Azure resource group
#>
function New-AzureResourceGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$Location
    )
    
    try {
        Write-InfoLog -Message "Managing resource group: $ResourceGroupName" -Category 'ResourceGroup'
        
        # Check if resource group exists
        $existingRG = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
        
        if ($existingRG) {
            Write-InfoLog -Message "Resource group already exists: $ResourceGroupName" -Category 'ResourceGroup'
            
            # Validate location match
            if ($existingRG.Location -ne $Location) {
                Write-WarningLog -Message "Resource group location mismatch. Expected: $Location, Found: $($existingRG.Location)" -Category 'ResourceGroup'
            }
            
            return $existingRG
        }
        
        # Create new resource group
        if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Create Azure resource group")) {
            $newRG = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop
            Write-SuccessLog -Message "Resource group created successfully: $ResourceGroupName" -Category 'ResourceGroup'
            $script:DeploymentMetrics.ResourcesCreated++
            return $newRG
        }
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-ErrorLog -Message "Resource group not found and creation failed" -Category 'ResourceGroup'
        throw "Failed to access or create resource group '$ResourceGroupName': $($_.Exception.Message)"
    }
    catch [System.UnauthorizedAccessException] {
        Write-ErrorLog -Message "Insufficient permissions to manage resource group" -Category 'ResourceGroup'
        throw "Insufficient permissions to manage resource group '$ResourceGroupName'"
    }
    catch {
        Write-ErrorLog -Message "Unexpected error managing resource group: $($_.Exception.Message)" -Category 'ResourceGroup'
        throw "Failed to manage resource group '$ResourceGroupName': $($_.Exception.Message)"
    }
}

#endregion

#region Virtual Network Deployment

<#
.SYNOPSIS
    Deploys Azure Virtual Network with proper subnet configuration
#>
function New-AzureVirtualNetwork {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$Location,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )
    
    try {
        $vnetName = "$($ProjectName.ToLower())vnet$(Get-Random -Minimum 1000 -Maximum 9999)"
        Write-InfoLog -Message "Deploying virtual network: $vnetName" -Category 'VirtualNetwork'
        
        if ($PSCmdlet.ShouldProcess($vnetName, "Create Azure virtual network")) {
            # Define subnet configuration
            $subnets = @(
                @{
                    Name          = "default"
                    AddressPrefix = "10.0.1.0/24"
                },
                @{
                    Name          = "app"
                    AddressPrefix = "10.0.2.0/24"
                },
                @{
                    Name          = "data"
                    AddressPrefix = "10.0.3.0/24"
                }
            )
            
            # Create virtual network
            $vnetParams = @{
                Name              = $vnetName
                ResourceGroupName = $ResourceGroupName
                Location          = $Location
                AddressPrefix     = "10.0.0.0/16"
                Subnet            = $subnets
            }
            
            $vnet = New-AzVirtualNetwork @vnetParams -ErrorAction Stop
            
            Write-SuccessLog -Message "Virtual network created successfully: $vnetName" -Category 'VirtualNetwork'
            Write-InfoLog -Message "Address space: $($vnet.AddressSpace.AddressPrefixes)" -Category 'VirtualNetwork'
            Write-InfoLog -Message "Subnets: $($vnet.Subnets.Name -join ', ')" -Category 'VirtualNetwork'
            
            $script:DeploymentMetrics.ResourcesCreated++
            return $vnet
        }
    }
    catch [System.Management.Automation.ValidationException] {
        Write-ErrorLog -Message "Invalid virtual network configuration" -Category 'VirtualNetwork'
        throw "Invalid virtual network configuration: $($_.Exception.Message)"
    }
    catch {
        Write-ErrorLog -Message "Failed to create virtual network: $($_.Exception.Message)" -Category 'VirtualNetwork'
        throw "Failed to create virtual network '$vnetName': $($_.Exception.Message)"
    }
}

#endregion

#region Monitoring and Backup Setup

<#
.SYNOPSIS
    Configures Azure Monitor and Log Analytics workspace
#>
function New-AzureMonitoring {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$Location,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )
    
    try {
        if (-not $EnableMonitoring) {
            Write-InfoLog -Message "Monitoring disabled, skipping Log Analytics setup" -Category 'Monitoring'
            return
        }
        
        $workspaceName = "$($ProjectName.ToLower())law$(Get-Random -Minimum 1000 -Maximum 9999)"
        Write-InfoLog -Message "Creating Log Analytics workspace: $workspaceName" -Category 'Monitoring'
        
        if ($PSCmdlet.ShouldProcess($workspaceName, "Create Log Analytics workspace")) {
            $workspace = New-AzOperationalInsightsWorkspace -Name $workspaceName -ResourceGroupName $ResourceGroupName -Location $Location -ErrorAction Stop
            
            Write-SuccessLog -Message "Log Analytics workspace created: $workspaceName" -Category 'Monitoring'
            Write-InfoLog -Message "Workspace ID: $($workspace.CustomerId)" -Category 'Monitoring'
            
            $script:DeploymentMetrics.ResourcesCreated++
            return $workspace
        }
    }
    catch {
        Write-ErrorLog -Message "Failed to create Log Analytics workspace: $($_.Exception.Message)" -Category 'Monitoring'
        $script:DeploymentMetrics.Errors++
        # Don't throw - monitoring is optional
    }
}

<#
.SYNOPSIS
    Configures Azure Backup vault
#>
function New-AzureBackupVault {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$Location,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )
    
    try {
        if (-not $EnableBackup) {
            Write-InfoLog -Message "Backup disabled, skipping Recovery Services vault setup" -Category 'Backup'
            return
        }
        
        $vaultName = "$($ProjectName.ToLower())rsv$(Get-Random -Minimum 1000 -Maximum 9999)"
        Write-InfoLog -Message "Creating Recovery Services vault: $vaultName" -Category 'Backup'
        
        if ($PSCmdlet.ShouldProcess($vaultName, "Create Recovery Services vault")) {
            $vault = New-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $ResourceGroupName -Location $Location -ErrorAction Stop
            
            Write-SuccessLog -Message "Recovery Services vault created: $vaultName" -Category 'Backup'
            
            $script:DeploymentMetrics.ResourcesCreated++
            return $vault
        }
    }
    catch {
        Write-ErrorLog -Message "Failed to create Recovery Services vault: $($_.Exception.Message)" -Category 'Backup'
        $script:DeploymentMetrics.Errors++
        # Don't throw - backup is optional
    }
}

#endregion

#region Main Deployment Logic

try {
    # Step 1: Validate authentication
    Test-AzureAuthentication
    
    # Step 2: Create/validate resource group
    $resourceGroup = New-AzureResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location
    
    # Step 3: Deploy virtual network
    $virtualNetwork = New-AzureVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location -ProjectName $ProjectName
    
    # Step 4: Configure monitoring (if enabled)
    $logAnalytics = New-AzureMonitoring -ResourceGroupName $ResourceGroupName -Location $Location -ProjectName $ProjectName
    
    # Step 5: Configure backup (if enabled)
    $backupVault = New-AzureBackupVault -ResourceGroupName $ResourceGroupName -Location $Location -ProjectName $ProjectName
    
    # Calculate deployment duration
    $script:DeploymentMetrics.Duration = (Get-Date) - $script:DeploymentStartTime
    
    # Log deployment completion
    Write-SuccessLog -Message "Azure infrastructure deployment completed successfully" -Category 'Deployment' -Properties @{
        'Duration'         = $script:DeploymentMetrics.Duration.ToString()
        'ResourcesCreated' = $script:DeploymentMetrics.ResourcesCreated
        'ResourcesUpdated' = $script:DeploymentMetrics.ResourcesUpdated
        'Errors'           = $script:DeploymentMetrics.Errors
        'Warnings'         = $script:DeploymentMetrics.Warnings
    }
    
    # Return deployment summary
    $deploymentSummary = @{
        'ResourceGroup'  = $resourceGroup
        'VirtualNetwork' = $virtualNetwork
        'LogAnalytics'   = $logAnalytics
        'BackupVault'    = $backupVault
        'Metrics'        = $script:DeploymentMetrics
        'DeploymentTime' = $script:DeploymentStartTime
    }
    
    return $deploymentSummary
}
catch {
    # Log deployment failure
    $script:DeploymentMetrics.Duration = (Get-Date) - $script:DeploymentStartTime
    $script:DeploymentMetrics.Errors++
    
    Write-ErrorLog -Message "Azure infrastructure deployment failed" -Category 'Deployment' -ErrorRecord $_ -Properties @{
        'Duration' = $script:DeploymentMetrics.Duration.ToString()
        'Errors'   = $script:DeploymentMetrics.Errors
    }
    
    # Re-throw the exception
    throw
}
finally {
    # Always log final metrics
    $metrics = Get-LoggingMetrics
    if ($metrics) {
        Write-InfoLog -Message "Logging metrics summary" -Category 'Metrics' -Properties @{
            'TotalLogs' = $metrics.TotalLogs
            'Errors'    = $metrics.Errors
            'Warnings'  = $metrics.Warnings
            'LogRate'   = [math]::Round($metrics.LogRate, 2)
        }
    }
}

#endregion
