function Get-IoTEdgeDeploymentParameters {
    <#
    .SYNOPSIS
        Gets IoT/Edge deployment parameters from user input.
    
    .DESCRIPTION
        Prompts the user for IoT/Edge deployment parameters and returns them as a hashtable.
    
    .PARAMETER DeploymentType
        The type of IoT/Edge deployment (azureiothub, azureiotedge, etc.).
    
    .PARAMETER Config
        The configuration object containing default values.
    
    .EXAMPLE
        Get-IoTEdgeDeploymentParameters -DeploymentType "azureiothub" -Config $config
    
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
        Write-ColorOutput "`nCollecting IoT/Edge deployment parameters..." -ForegroundColor Cyan
        
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
            "azureiothub" {
                $iothubName = Read-Host "IoT Hub Name (default: $($config.env)-$($config.loc)-iothub-$($config.project))"
                if ([string]::IsNullOrWhiteSpace($iothubName)) {
                    $iothubName = "$($config.env)-$($config.loc)-iothub-$($config.project)"
                }
                
                $sku = Read-Host "SKU (F1/S1/S2/S3) (default: S1)"
                if ([string]::IsNullOrWhiteSpace($sku)) {
                    $sku = "S1"
                }
                else {
                    # Validate SKU input against allowed values
                    $allowedSkus = @("F1", "S1", "S2", "S3")
                    if ($sku -notin $allowedSkus) {
                        Write-ColorOutput "Invalid SKU value. Allowed values are: F1, S1, S2, S3. Using default value: S1" -ForegroundColor Yellow
                        $sku = "S1"
                    }
                }
                
                $unitCount = Read-Host "Unit Count (1-200) (default: 1)"
                if ([string]::IsNullOrWhiteSpace($unitCount)) {
                    $unitCount = 1
                }
                else {
                    # Validate unit count input
                    try {
                        $unitCountInt = [int]$unitCount
                        if ($unitCountInt -lt 1 -or $unitCountInt -gt 200) {
                            Write-ColorOutput "Invalid unit count value. Must be between 1 and 200. Using default value: 1" -ForegroundColor Yellow
                            $unitCount = 1
                        }
                        else {
                            $unitCount = $unitCountInt
                        }
                    }
                    catch {
                        Write-ColorOutput "Invalid unit count input. Must be a valid integer. Using default value: 1" -ForegroundColor Yellow
                        $unitCount = 1
                    }
                }
                
                $enableDeviceProvisioning = Read-Host "Enable Device Provisioning Service (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableDeviceProvisioning) -or $enableDeviceProvisioning -eq "n") {
                    $enableDeviceProvisioning = $false
                }
                else {
                    $enableDeviceProvisioning = $true
                }
                
                $enableFileUpload = Read-Host "Enable File Upload Notifications (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableFileUpload) -or $enableFileUpload -eq "n") {
                    $enableFileUpload = $false
                }
                else {
                    $enableFileUpload = $true
                }
                
                $enableCloudToDeviceMessages = Read-Host "Enable Cloud-to-Device Messaging (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableCloudToDeviceMessages) -or $enableCloudToDeviceMessages -eq "y") {
                    $enableCloudToDeviceMessages = $true
                }
                else {
                    $enableCloudToDeviceMessages = $false
                }
                
                $enableDeviceTwin = Read-Host "Enable Device Twin Functionality (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableDeviceTwin) -or $enableDeviceTwin -eq "y") {
                    $enableDeviceTwin = $true
                }
                else {
                    $enableDeviceTwin = $false
                }
                
                $enableMessageRouting = Read-Host "Enable Message Routing (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableMessageRouting) -or $enableMessageRouting -eq "n") {
                    $enableMessageRouting = $false
                }
                else {
                    $enableMessageRouting = $true
                }
                
                $enableEventHubEndpoint = Read-Host "Enable Event Hub Endpoint (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableEventHubEndpoint) -or $enableEventHubEndpoint -eq "n") {
                    $enableEventHubEndpoint = $false
                }
                else {
                    $enableEventHubEndpoint = $true
                }
                
                $enableServiceBusEndpoint = Read-Host "Enable Service Bus Endpoint (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableServiceBusEndpoint) -or $enableServiceBusEndpoint -eq "n") {
                    $enableServiceBusEndpoint = $false
                }
                else {
                    $enableServiceBusEndpoint = $true
                }
                
                $enableStorageEndpoint = Read-Host "Enable Storage Endpoint (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableStorageEndpoint) -or $enableStorageEndpoint -eq "n") {
                    $enableStorageEndpoint = $false
                }
                else {
                    $enableStorageEndpoint = $true
                }
                
                return @{
                    ResourceGroup               = $resourceGroup
                    Location                    = $location
                    IoTHubName                  = $iothubName
                    Sku                         = $sku
                    UnitCount                   = $unitCount
                    EnableDeviceProvisioning    = $enableDeviceProvisioning
                    EnableFileUpload            = $enableFileUpload
                    EnableCloudToDeviceMessages = $enableCloudToDeviceMessages
                    EnableDeviceTwin            = $enableDeviceTwin
                    EnableMessageRouting        = $enableMessageRouting
                    EnableEventHubEndpoint      = $enableEventHubEndpoint
                    EnableServiceBusEndpoint    = $enableServiceBusEndpoint
                    EnableStorageEndpoint       = $enableStorageEndpoint
                }
            }
            
            "azureiotedge" {
                $iothubName = Read-Host "IoT Hub Name (default: $($config.env)-$($config.loc)-iothub-$($config.project))"
                if ([string]::IsNullOrWhiteSpace($iothubName)) {
                    $iothubName = "$($config.env)-$($config.loc)-iothub-$($config.project)"
                }
                
                $edgeDeviceName = Read-Host "Edge Device Name (leave empty for auto-generation)"
                if ([string]::IsNullOrWhiteSpace($edgeDeviceName)) {
                    $edgeDeviceName = $null
                }
                
                $edgeDeviceType = Read-Host "Edge Device Type (Linux/Windows) (default: Linux)"
                if ([string]::IsNullOrWhiteSpace($edgeDeviceType)) {
                    $edgeDeviceType = "Linux"
                }
                else {
                    # Validate edge device type input
                    $allowedDeviceTypes = @("Linux", "Windows")
                    if ($edgeDeviceType -notin $allowedDeviceTypes) {
                        Write-ColorOutput "Invalid edge device type. Allowed values are: Linux, Windows. Using default value: Linux" -ForegroundColor Yellow
                        $edgeDeviceType = "Linux"
                    }
                }
                
                $containerRegistryName = Read-Host "Container Registry Name (optional, leave empty to skip)"
                if ([string]::IsNullOrWhiteSpace($containerRegistryName)) {
                    $containerRegistryName = $null
                }
                
                $enableSimulatedDevice = Read-Host "Create Simulated Edge Device (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableSimulatedDevice) -or $enableSimulatedDevice -eq "n") {
                    $enableSimulatedDevice = $false
                }
                else {
                    $enableSimulatedDevice = $true
                }
                
                $enableCustomModules = Read-Host "Deploy Custom Edge Modules (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableCustomModules) -or $enableCustomModules -eq "n") {
                    $enableCustomModules = $false
                }
                else {
                    $enableCustomModules = $true
                }
                
                $moduleNames = @()
                if ($enableCustomModules) {
                    $moduleInput = Read-Host "Custom Module Names (comma-separated, e.g., sensor-module,processor-module)"
                    if (-not [string]::IsNullOrWhiteSpace($moduleInput)) {
                        $moduleNames = $moduleInput.Split(",") | ForEach-Object { $_.Trim() }
                    }
                }
                
                $enableBuiltInModules = Read-Host "Enable Built-in Edge Modules (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableBuiltInModules) -or $enableBuiltInModules -eq "y") {
                    $enableBuiltInModules = $true
                }
                else {
                    $enableBuiltInModules = $false
                }
                
                $enableDeviceProvisioning = Read-Host "Use Device Provisioning Service (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableDeviceProvisioning) -or $enableDeviceProvisioning -eq "n") {
                    $enableDeviceProvisioning = $false
                }
                else {
                    $enableDeviceProvisioning = $true
                }
                
                $enableMonitoring = Read-Host "Enable Monitoring and Logging (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableMonitoring) -or $enableMonitoring -eq "y") {
                    $enableMonitoring = $true
                }
                else {
                    $enableMonitoring = $false
                }
                
                return @{
                    ResourceGroup            = $resourceGroup
                    Location                 = $location
                    IoTHubName               = $iothubName
                    EdgeDeviceName           = $edgeDeviceName
                    EdgeDeviceType           = $edgeDeviceType
                    ContainerRegistryName    = $containerRegistryName
                    EnableSimulatedDevice    = $enableSimulatedDevice
                    EnableCustomModules      = $enableCustomModules
                    ModuleNames              = $moduleNames
                    EnableBuiltInModules     = $enableBuiltInModules
                    EnableDeviceProvisioning = $enableDeviceProvisioning
                    EnableMonitoring         = $enableMonitoring
                }
            }
            
            default {
                Write-ColorOutput "Unsupported deployment type: $DeploymentType" -ForegroundColor Red
                return $null
            }
        }
    }
    catch {
        Write-ColorOutput "Error getting IoT/Edge deployment parameters: $_" -ForegroundColor Red
        return $null
    }
} 