function Deploy-AzureIoTEdgeRuntime {
    <#
    .SYNOPSIS
        Deploys Azure IoT Edge Runtime.
    
    .DESCRIPTION
        Deploys Azure IoT Edge Runtime with configurable parameters including
        edge modules, device provisioning, and container registry integration.
    
    .PARAMETER ResourceGroup
        The resource group name where the IoT Edge device will be deployed.
    
    .PARAMETER Location
        The Azure location for the deployment.
    
    .PARAMETER IoTHubName
        The name of the IoT Hub to connect to.
    
    .PARAMETER EdgeDeviceName
        The name of the IoT Edge device.
    
    .PARAMETER EdgeDeviceType
        The type of edge device (Linux, Windows).
    
    .PARAMETER ContainerRegistryName
        The name of the container registry for edge modules.
    
    .PARAMETER EnableSimulatedDevice
        Whether to create a simulated edge device.
    
    .PARAMETER EnableCustomModules
        Whether to deploy custom edge modules.
    
    .PARAMETER ModuleNames
        Array of custom module names to deploy.
    
    .PARAMETER EnableBuiltInModules
        Whether to enable built-in edge modules.
    
    .PARAMETER EnableDeviceProvisioning
        Whether to use device provisioning service.
    
    .PARAMETER EnableMonitoring
        Whether to enable monitoring and logging.
    
    .EXAMPLE
        Deploy-AzureIoTEdgeRuntime -ResourceGroup "my-rg" -Location "southafricanorth" -IoTHubName "my-iothub"
    
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
        [string]$IoTHubName,
        
        [Parameter(Mandatory = $false)]
        [string]$EdgeDeviceName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Linux", "Windows")]
        [string]$EdgeDeviceType = "Linux",
        
        [Parameter(Mandatory = $false)]
        [string]$ContainerRegistryName,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableSimulatedDevice = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableCustomModules = $false,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ModuleNames = @(),
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableBuiltInModules = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableDeviceProvisioning = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableMonitoring = $true
    )
    
    try {
        Write-ColorOutput "Starting Azure IoT Edge Runtime deployment..." -ForegroundColor Cyan
        
        # Check if resource group exists
        $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
        if ($rgExists -ne "true") {
            Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
            az group create --name $ResourceGroup --location $Location
        }
        
        # Check if IoT Hub exists
        $iothubExists = az iot hub show --name $IoTHubName --resource-group $ResourceGroup --output tsv 2>$null
        if (-not $iothubExists) {
            Write-ColorOutput "IoT Hub '$IoTHubName' not found. Creating IoT Hub..." -ForegroundColor Yellow
            az iot hub create `
                --name $IoTHubName `
                --resource-group $ResourceGroup `
                --location $Location `
                --sku S1 `
                --unit 1
        }
        
        # Generate edge device name if not provided
        if (-not $EdgeDeviceName) {
            $EdgeDeviceName = "$($IoTHubName.ToLower())edge$(Get-Random -Minimum 1000 -Maximum 9999)"
        }
        
        # Create IoT Edge device
        Write-ColorOutput "Creating IoT Edge device: $EdgeDeviceName" -ForegroundColor Yellow
        $deviceExists = az iot hub device-identity show --hub-name $IoTHubName --device-id $EdgeDeviceName --output tsv 2>$null
        if (-not $deviceExists) {
            az iot hub device-identity create `
                --hub-name $IoTHubName `
                --device-id $EdgeDeviceName `
                --edge-enabled
        }
        
        # Get device connection string
        $deviceConnectionString = az iot hub device-identity connection-string show `
            --hub-name $IoTHubName `
            --device-id $EdgeDeviceName `
            --query connectionString `
            --output tsv
        
        # Create container registry if specified
        if ($ContainerRegistryName) {
            Write-ColorOutput "Creating container registry: $ContainerRegistryName" -ForegroundColor Yellow
            $acrExists = az acr show --name $ContainerRegistryName --resource-group $ResourceGroup --output tsv 2>$null
            if (-not $acrExists) {
                az acr create `
                    --name $ContainerRegistryName `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --sku Basic
            }
            
            # Get ACR credentials
            $acrLoginServer = az acr show --name $ContainerRegistryName --resource-group $ResourceGroup --query loginServer --output tsv
            $acrUsername = az acr credential show --name $ContainerRegistryName --resource-group $ResourceGroup --query username --output tsv
            $acrPassword = az acr credential show --name $ContainerRegistryName --resource-group $ResourceGroup --query "passwords[0].value" --output tsv
        }
        
        # Create deployment manifest
        Write-ColorOutput "Creating deployment manifest..." -ForegroundColor Yellow
        $deploymentManifest = @{
            modulesContent = @{
                '$edgeAgent'          = @{
                    properties.desired = @{
                        modules = @{}
                        runtime       = @{
                            settings = @{
                                registryCredentials = @{}
                            }
                        }
                        schemaVersion = "1.0"
                        systemModules = @{
                            edgeAgent = @{
                                settings = @{
                                    image = "mcr.microsoft.com/azureiotedge-agent:1.4"
                                }
                                type     = "docker"
                            }
                            edgeHub   = @{
                                settings      = @{
                                    image         = "mcr.microsoft.com/azureiotedge-hub:1.4"
                                    createOptions = '{"HostConfig":{"PortBindings":{"5671/tcp":[{"HostPort":"5671"}],"8883/tcp":[{"HostPort":"8883"}],"443/tcp":[{"HostPort":"443"}]}}}'
                                }
                                type          = "docker"
                                env           = @{
                                    OptimizeForPerformance = @{
                                        value = "false"
                                    }
                                }
                                status        = "running"
                                restartPolicy = "always"
                            }
                        }
                    }
                }
                '$edgeHub' = @{
                    properties.desired = @{
                        routes = @{
                            route = "FROM /messages/* INTO $('$upstream')"
                        }
                        schemaVersion = "1.0"
                        storeAndForwardConfiguration = @{
                            timeToLiveSecs = 7200
                        }
                    }
                }
            }
        }
        
        # Add container registry credentials if specified
        if ($ContainerRegistryName) {
            $deploymentManifest.modulesContent.'$edgeAgent'.properties.desired.runtime.settings.registryCredentials.$ContainerRegistryName = @{
                username = $acrUsername
                password = $acrPassword
                address  = $acrLoginServer
            }
        }
        
        # Add custom modules if specified
        if ($EnableCustomModules -and $ModuleNames.Count -gt 0) {
            foreach ($moduleName in $ModuleNames) {
                $moduleImage = if ($ContainerRegistryName) {
                    "$acrLoginServer/$moduleName:latest"
                }
                else {
                    "mcr.microsoft.com/azureiotedge-simulated-temperature-sensor:1.0"
                }
                
                $deploymentManifest.modulesContent.'$edgeAgent'.properties.desired.modules.$moduleName = @{
                    version       = "1.0"
                    type          = "docker"
                    status        = "running"
                    restartPolicy = "always"
                    settings      = @{
                        image         = $moduleImage
                        createOptions = "{}"
                    }
                }
            }
        }
        
        # Add built-in modules if enabled
        if ($EnableBuiltInModules) {
            # Add simulated temperature sensor module
            $deploymentManifest.modulesContent.'$edgeAgent'.properties.desired.modules.SimulatedTemperatureSensor = @{
                version       = "1.0"
                type          = "docker"
                status        = "running"
                restartPolicy = "always"
                settings      = @{
                    image         = "mcr.microsoft.com/azureiotedge-simulated-temperature-sensor:1.0"
                    createOptions = "{}"
                }
            }
        }
        
        # Save deployment manifest to file
        $manifestPath = Join-Path -Path $env:TEMP -ChildPath "edge-deployment-manifest.json"
        $deploymentManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath
        
        # Create deployment
        Write-ColorOutput "Creating IoT Edge deployment..." -ForegroundColor Yellow
        $deploymentName = "$($EdgeDeviceName)-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        
        az iot edge deployment create `
            --hub-name $IoTHubName `
            --deployment-id $deploymentName `
            --content $manifestPath `
            --target-condition "deviceId='$EdgeDeviceName'" `
            --priority 10
        
        # Create simulated device if requested
        if ($EnableSimulatedDevice) {
            Write-ColorOutput "Creating simulated IoT Edge device..." -ForegroundColor Yellow
            
            # Create a simple deployment script for the simulated device
            $deploymentScript = @"
#!/bin/bash
# IoT Edge Runtime Installation Script

# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# Add Microsoft GPG key
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

# Add Azure IoT Edge repository
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-iot-edge/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azure-iot-edge.list

# Update package index again
sudo apt-get update

# Install IoT Edge runtime
sudo apt-get install -y iotedge

# Configure IoT Edge
sudo iotedge config mp --connection-string "$deviceConnectionString"

# Start IoT Edge
sudo systemctl enable iotedge
sudo systemctl start iotedge

echo "IoT Edge Runtime installed and configured successfully!"
echo "Device Connection String: $deviceConnectionString"
"@
            
            $scriptPath = Join-Path -Path $env:TEMP -ChildPath "install-iotedge.sh"
            $deploymentScript | Set-Content -Path $scriptPath
            
            Write-ColorOutput "Installation script created: $scriptPath" -ForegroundColor Green
            Write-ColorOutput "Run this script on your edge device to install IoT Edge Runtime" -ForegroundColor Yellow
        }
        
        # Enable monitoring if requested
        if ($EnableMonitoring) {
            Write-ColorOutput "Enabling monitoring and logging..." -ForegroundColor Yellow
            
            # Create Log Analytics workspace if it doesn't exist
            $workspaceName = "$($IoTHubName.ToLower())workspace$(Get-Random -Minimum 1000 -Maximum 9999)"
            $workspaceExists = az monitor log-analytics workspace show --workspace-name $workspaceName --resource-group $ResourceGroup --output tsv 2>$null
            if (-not $workspaceExists) {
                az monitor log-analytics workspace create `
                    --workspace-name $workspaceName `
                    --resource-group $ResourceGroup `
                    --location $Location
            }
            
            # Get workspace ID
            $workspaceId = az monitor log-analytics workspace show `
                --workspace-name $workspaceName `
                --resource-group $ResourceGroup `
                --query customerId `
                --output tsv
            
            # Enable IoT Hub diagnostic settings
            az monitor diagnostic-settings create `
                --resource $IoTHubName `
                --resource-group $ResourceGroup `
                --resource-type Microsoft.Devices/IotHubs `
                --name "iot-hub-diagnostics" `
                --workspace $workspaceId `
                --logs '[{"category": "Connections", "enabled": true}, {"category": "DeviceTelemetry", "enabled": true}, {"category": "C2DCommands", "enabled": true}, {"category": "DeviceIdentityOperations", "enabled": true}, {"category": "FileUploadOperations", "enabled": true}, {"category": "Routes", "enabled": true}, {"category": "D2CTwinOperations", "enabled": true}, {"category": "C2DTwinOperations", "enabled": true}, {"category": "TwinQueries", "enabled": true}, {"category": "JobsOperations", "enabled": true}, {"category": "DirectMethods", "enabled": true}, {"category": "E2EDiagnostics", "enabled": true}, {"category": "Configurations", "enabled": true}]'
        }
        
        # Get device details
        Write-ColorOutput "Getting device details..." -ForegroundColor Yellow
        $deviceDetails = az iot hub device-identity show `
            --hub-name $IoTHubName `
            --device-id $EdgeDeviceName `
            --output json | ConvertFrom-Json
        
        # Display deployment summary
        Write-ColorOutput "`nAzure IoT Edge Runtime deployment completed successfully!" -ForegroundColor Green
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "IoT Hub Name: $IoTHubName" -ForegroundColor Gray
        Write-ColorOutput "Edge Device Name: $EdgeDeviceName" -ForegroundColor Gray
        Write-ColorOutput "Device Type: $EdgeDeviceType" -ForegroundColor Gray
        Write-ColorOutput "Device Connection String: $deviceConnectionString" -ForegroundColor Gray
        Write-ColorOutput "Deployment Name: $deploymentName" -ForegroundColor Gray
        Write-ColorOutput "Device ID: $($deviceDetails.deviceId)" -ForegroundColor Gray
        
        if ($ContainerRegistryName) {
            Write-ColorOutput "Container Registry: $ContainerRegistryName" -ForegroundColor Gray
            Write-ColorOutput "ACR Login Server: $acrLoginServer" -ForegroundColor Gray
        }
        
        if ($EnableMonitoring) {
            Write-ColorOutput "Log Analytics Workspace: $workspaceName" -ForegroundColor Gray
        }
        
        # Return deployment info
        return @{
            ResourceGroup                = $ResourceGroup
            IoTHubName                   = $IoTHubName
            EdgeDeviceName               = $EdgeDeviceName
            EdgeDeviceType               = $EdgeDeviceType
            DeviceConnectionString       = $deviceConnectionString
            DeploymentName               = $deploymentName
            ContainerRegistryName        = $ContainerRegistryName
            ContainerRegistryLoginServer = if ($ContainerRegistryName) { $acrLoginServer } else { $null }
            LogAnalyticsWorkspace        = if ($EnableMonitoring) { $workspaceName } else { $null }
            DeviceDetails                = $deviceDetails
            DeploymentManifest           = $deploymentManifest
        }
    }
    catch {
        Write-ColorOutput "Error deploying Azure IoT Edge Runtime: $_" -ForegroundColor Red
        throw
    }
} 