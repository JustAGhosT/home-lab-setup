function Configure-IoTHubEndpoints {
    <#
    .SYNOPSIS
        Configures IoT Hub endpoints and settings.
    
    .DESCRIPTION
        Configures endpoints and settings for IoT Hub deployments,
        including updating application configuration files.
    
    .PARAMETER ResourceGroup
        The resource group name.
    
    .PARAMETER IoTHubName
        The IoT Hub name.
    
    .PARAMETER ConnectionString
        The IoT Hub connection string.
    
    .PARAMETER EventHubConnectionString
        The Event Hub connection string.
    
    .PARAMETER DeviceProvisioningService
        The device provisioning service name.
    
    .PARAMETER ProjectPath
        The path to the project to configure.
    
    .EXAMPLE
        Configure-IoTHubEndpoints -ResourceGroup "my-rg" -IoTHubName "my-iothub"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$IoTHubName,
        
        [Parameter(Mandatory = $false)]
        [string]$ConnectionString,
        
        [Parameter(Mandatory = $false)]
        [string]$EventHubConnectionString,
        
        [Parameter(Mandatory = $false)]
        [string]$DeviceProvisioningService,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )
    
    try {
        Write-ColorOutput "Configuring IoT Hub endpoints..." -ForegroundColor Cyan
        
        # Get connection strings if not provided
        if (-not $ConnectionString) {
            $ConnectionString = az iot hub connection-string show `
                --name $IoTHubName `
                --resource-group $ResourceGroup `
                --query connectionString `
                --output tsv
        }
        
        if (-not $EventHubConnectionString) {
            $EventHubConnectionString = az iot hub connection-string show `
                --name $IoTHubName `
                --resource-group $ResourceGroup `
                --event-hub `
                --query connectionString `
                --output tsv
        }
        
        # Get IoT Hub details
        $iothubDetails = az iot hub show `
            --name $IoTHubName `
            --resource-group $ResourceGroup `
            --output json | ConvertFrom-Json
        
        # Get shared access policies
        $policies = az iot hub policy list `
            --name $IoTHubName `
            --resource-group $ResourceGroup `
            --output json | ConvertFrom-Json
        
        # Display connection information
        Write-ColorOutput "`nIoT Hub Connection Information:" -ForegroundColor Green
        Write-ColorOutput "IoT Hub Name: $IoTHubName" -ForegroundColor Gray
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "Connection String: $ConnectionString" -ForegroundColor Gray
        Write-ColorOutput "Event Hub Connection String: $EventHubConnectionString" -ForegroundColor Gray
        Write-ColorOutput "IoT Hub ID: $($iothubDetails.id)" -ForegroundColor Gray
        Write-ColorOutput "SKU: $($iothubDetails.sku.name)" -ForegroundColor Gray
        Write-ColorOutput "Unit Count: $($iothubDetails.sku.capacity)" -ForegroundColor Gray
        
        if ($DeviceProvisioningService) {
            Write-ColorOutput "Device Provisioning Service: $DeviceProvisioningService" -ForegroundColor Gray
        }
        
        # Update project configuration files if project path is provided
        if ($ProjectPath -and (Test-Path -Path $ProjectPath)) {
            Write-ColorOutput "`nUpdating project configuration files..." -ForegroundColor Yellow
            
            # Update appsettings.json for .NET projects
            $appSettingsPath = Join-Path -Path $ProjectPath -ChildPath "appsettings.json"
            if (Test-Path -Path $appSettingsPath) {
                Write-ColorOutput "Updating appsettings.json..." -ForegroundColor Gray
                $appSettings = Get-Content -Path $appSettingsPath | ConvertFrom-Json
                
                if (-not $appSettings.IoTHub) {
                    $appSettings | Add-Member -MemberType NoteProperty -Name "IoTHub" -Value @{}
                }
                
                $appSettings.IoTHub.Name = $IoTHubName
                $appSettings.IoTHub.ResourceGroup = $ResourceGroup
                $appSettings.IoTHub.ConnectionString = $ConnectionString
                $appSettings.IoTHub.EventHubConnectionString = $EventHubConnectionString
                $appSettings.IoTHub.DeviceProvisioningService = $DeviceProvisioningService
                $appSettings.IoTHub.Sku = $iothubDetails.sku.name
                $appSettings.IoTHub.UnitCount = $iothubDetails.sku.capacity
                
                $appSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $appSettingsPath
                Write-ColorOutput "Updated appsettings.json" -ForegroundColor Green
            }
            
            # Update package.json for Node.js projects
            $packageJsonPath = Join-Path -Path $ProjectPath -ChildPath "package.json"
            if (Test-Path -Path $packageJsonPath) {
                Write-ColorOutput "Updating package.json..." -ForegroundColor Gray
                $packageJson = Get-Content -Path $packageJsonPath | ConvertFrom-Json
                
                if (-not $packageJson.config) {
                    $packageJson | Add-Member -MemberType NoteProperty -Name "config" -Value @{}
                }
                
                $packageJson.config.iothubName = $IoTHubName
                $packageJson.config.iothubResourceGroup = $ResourceGroup
                $packageJson.config.iothubConnectionString = $ConnectionString
                $packageJson.config.iothubEventHubConnectionString = $EventHubConnectionString
                $packageJson.config.iothubDeviceProvisioningService = $DeviceProvisioningService
                $packageJson.config.iothubSku = $iothubDetails.sku.name
                $packageJson.config.iothubUnitCount = $iothubDetails.sku.capacity
                
                $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath
                Write-ColorOutput "Updated package.json" -ForegroundColor Green
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            @"
# Azure IoT Hub Configuration
AZURE_IOT_HUB_NAME=$IoTHubName
AZURE_IOT_HUB_RESOURCE_GROUP=$ResourceGroup
AZURE_IOT_HUB_CONNECTION_STRING=$ConnectionString
AZURE_IOT_HUB_EVENT_HUB_CONNECTION_STRING=$EventHubConnectionString
AZURE_IOT_HUB_DEVICE_PROVISIONING_SERVICE=$DeviceProvisioningService
AZURE_IOT_HUB_SKU=$($iothubDetails.sku.name)
AZURE_IOT_HUB_UNIT_COUNT=$($iothubDetails.sku.capacity)
"@ | Set-Content -Path $envPath
            Write-ColorOutput "Created .env file" -ForegroundColor Green
        }
        
        # Save connection information to a configuration file
        $configPath = Join-Path -Path $env:USERPROFILE -ChildPath ".homelab\iothub-connections.json"
        $configDir = Split-Path -Path $configPath -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $connectionConfig = @{
            ResourceGroup             = $ResourceGroup
            IoTHubName                = $IoTHubName
            ConnectionString          = $ConnectionString
            EventHubConnectionString  = $EventHubConnectionString
            DeviceProvisioningService = $DeviceProvisioningService
            Sku                       = $iothubDetails.sku.name
            UnitCount                 = $iothubDetails.sku.capacity
            IoTHubId                  = $iothubDetails.id
            CreatedAt                 = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath
        Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
        
        Write-ColorOutput "`nIoT Hub endpoint configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring IoT Hub endpoints: $_" -ForegroundColor Red
        throw
    }
} 