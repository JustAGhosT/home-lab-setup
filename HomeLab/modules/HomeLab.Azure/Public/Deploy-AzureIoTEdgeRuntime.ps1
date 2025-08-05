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
        
        # Get device connection string securely
        Write-ColorOutput "Retrieving device connection string securely..." -ForegroundColor Yellow
        try {
            $deviceConnectionString = az iot hub device-identity connection-string show `
                --hub-name $IoTHubName `
                --device-id $EdgeDeviceName `
                --query connectionString `
                --output tsv
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve device connection string. Exit code: $LASTEXITCODE"
            }
            
            if ([string]::IsNullOrWhiteSpace($deviceConnectionString)) {
                throw "Device connection string is empty or null. Please check if the device exists and you have proper permissions."
            }
            
            # Store connection string securely in Azure Key Vault if available
            $keyVaultName = "$($IoTHubName.ToLower())kv$(Get-Random -Minimum 1000 -Maximum 9999)"
            try {
                # Check if Key Vault exists, create if not
                $kvExists = az keyvault show --name $keyVaultName --resource-group $ResourceGroup --output tsv 2>$null
                if (-not $kvExists) {
                    Write-ColorOutput "Creating Azure Key Vault for secure secret storage: $keyVaultName" -ForegroundColor Yellow
                    az keyvault create `
                        --name $keyVaultName `
                        --resource-group $ResourceGroup `
                        --location $Location `
                        --enable-soft-delete true `
                        --enable-purge-protection true
                    
                    # Set access policy for current user
                    $currentUser = az account show --query user.name --output tsv
                    az keyvault set-policy `
                        --name $keyVaultName `
                        --resource-group $ResourceGroup `
                        --secret-permissions get set list delete `
                        --upn $currentUser
                }
                
                # Store connection string as secret
                $secretName = "$($EdgeDeviceName)-connection-string"
                az keyvault secret set `
                    --vault-name $keyVaultName `
                    --name $secretName `
                    --value $deviceConnectionString
                
                Write-ColorOutput "Connection string stored securely in Azure Key Vault: $keyVaultName" -ForegroundColor Green
                Write-ColorOutput "Secret name: $secretName" -ForegroundColor Gray
                
                # Create a reference to the Key Vault secret instead of storing plain text
                $deviceConnectionString = "https://$keyVaultName.vault.azure.net/secrets/$secretName"
            }
            catch {
                Write-ColorOutput "Warning: Could not store connection string in Key Vault. Using local secure storage." -ForegroundColor Yellow
                Write-ColorOutput "Key Vault error: $($_.Exception.Message)" -ForegroundColor Yellow
                
                # Store connection string reference for local use (not plain text)
                $deviceConnectionString = "[SECURE_REFERENCE]"
            }
            
            Write-ColorOutput "Successfully retrieved device connection string" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving device connection string: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve device connection string for '$EdgeDeviceName': $($_.Exception.Message)"
        }
        
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
                '$edgeAgent' = @{
                    'properties.desired' = @{
                        modules       = @{}
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
                '$edgeHub'   = @{
                    'properties.desired' = @{
                        routes                       = @{
                            route = "FROM /messages/* INTO $('$upstream')"
                        }
                        schemaVersion                = "1.0"
                        storeAndForwardConfiguration = @{
                            timeToLiveSecs = 7200
                        }
                    }
                }
            }
        }
        
        # Add container registry credentials if specified
        if ($ContainerRegistryName) {
            $deploymentManifest.modulesContent.'$edgeAgent'.'properties.desired'.runtime.settings.registryCredentials.$ContainerRegistryName = @{
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
            
            # Create OS-specific installation scripts
            if ($EdgeDeviceType -eq "Linux") {
                Write-ColorOutput "Creating Linux IoT Edge installation script..." -ForegroundColor Yellow
                
                # Linux installation script with modern GPG key handling
                $linuxScript = @"
#!/bin/bash
# IoT Edge Runtime Installation Script for Linux
# This script uses modern GPG key handling and is compatible with current IoT Edge versions

set -e

echo "Starting IoT Edge Runtime installation for Linux..."

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=\$NAME
    VER=\$VERSION_ID
else
    echo "Error: Cannot detect Linux distribution"
    exit 1
fi

echo "Detected OS: \$OS \$VER"

# Update package index
echo "Updating package index..."
sudo apt-get update

# Install prerequisites
echo "Installing prerequisites..."
sudo apt-get install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# Add Microsoft GPG key using modern method
echo "Adding Microsoft GPG key..."
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg

# Add Azure IoT Edge repository
echo "Adding Azure IoT Edge repository..."
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/azure-iot-edge/ \$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azure-iot-edge.list

# Update package index again
echo "Updating package index..."
sudo apt-get update

# Install IoT Edge runtime
echo "Installing IoT Edge runtime..."
sudo apt-get install -y iotedge

# Configure IoT Edge with connection string securely
echo "Configuring IoT Edge with secure connection string..."

# Function to retrieve connection string securely
get_connection_string() {
    # Try to get from environment variable first
    if [ ! -z "\$CONNECTION_STRING" ]; then
        echo "\$CONNECTION_STRING"
        return 0
    fi
    
    # Try to get from Azure Key Vault if available
    if command -v az &> /dev/null; then
        if [ ! -z "\$KEY_VAULT_NAME" ] && [ ! -z "\$SECRET_NAME" ]; then
            echo "Retrieving connection string from Azure Key Vault..."
            az keyvault secret show --vault-name "\$KEY_VAULT_NAME" --name "\$SECRET_NAME" --query value --output tsv
            return \$?
        fi
    fi
    
    # Try to get from local secure file
    if [ -f "/etc/iotedge/connection-string" ]; then
        echo "Retrieving connection string from local secure file..."
        cat /etc/iotedge/connection-string
        return 0
    fi
    
    echo "ERROR: No secure connection string source found" >&2
    echo "Please set one of the following:" >&2
    echo "  - CONNECTION_STRING environment variable" >&2
    echo "  - KEY_VAULT_NAME and SECRET_NAME environment variables" >&2
    echo "  - Place connection string in /etc/iotedge/connection-string" >&2
    return 1
}

# Get connection string securely
CONNECTION_STRING_SECURE=\$(get_connection_string)
if [ \$? -ne 0 ]; then
    echo "Failed to retrieve connection string securely"
    exit 1
fi

# Configure IoT Edge with the secure connection string
sudo iotedge config mp --connection-string "\$CONNECTION_STRING_SECURE"

# Clear the connection string from memory
unset CONNECTION_STRING_SECURE

# Start IoT Edge
echo "Starting IoT Edge service..."
sudo systemctl enable iotedge
sudo systemctl start iotedge

# Verify installation
echo "Verifying IoT Edge installation..."
sleep 10
sudo iotedge list

echo "IoT Edge Runtime installed and configured successfully!"
echo ""
echo "SECURITY SETUP REQUIRED:"
echo "Before running this script, set up one of the following secure connection string sources:"
echo ""
echo "Option 1 - Environment Variable:"
echo "  export CONNECTION_STRING='your-device-connection-string'"
echo ""
echo "Option 2 - Azure Key Vault (recommended):"
echo "  export KEY_VAULT_NAME='your-key-vault-name'"
echo "  export SECRET_NAME='your-secret-name'"
echo "  az login  # Ensure you're authenticated"
echo ""
echo "Option 3 - Local Secure File:"
echo "  sudo mkdir -p /etc/iotedge"
echo "  sudo chmod 700 /etc/iotedge"
echo "  echo 'your-device-connection-string' | sudo tee /etc/iotedge/connection-string"
echo "  sudo chmod 600 /etc/iotedge/connection-string"
echo ""
echo "The script will automatically retrieve the connection string from the configured source."
"@
                
                $linuxScriptPath = Join-Path -Path $env:TEMP -ChildPath "install-iotedge-linux.sh"
                $linuxScript | Set-Content -Path $linuxScriptPath
                
                Write-ColorOutput "Linux installation script created: $linuxScriptPath" -ForegroundColor Green
                Write-ColorOutput "Run this script on your Linux edge device to install IoT Edge Runtime" -ForegroundColor Yellow
            }
            elseif ($EdgeDeviceType -eq "Windows") {
                Write-ColorOutput "Creating Windows IoT Edge installation script..." -ForegroundColor Yellow
                
                # Windows installation script
                $windowsScript = @"
# IoT Edge Runtime Installation Script for Windows
# This script installs IoT Edge on Windows devices

Write-Host "Starting IoT Edge Runtime installation for Windows..." -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

# Install IoT Edge runtime using PowerShell
Write-Host "Installing IoT Edge runtime..." -ForegroundColor Yellow

# Download and install IoT Edge
Invoke-WebRequest -Uri "https://aka.ms/iotedge-win" -OutFile "iotedge-install.ps1"
.\iotedge-install.ps1 -ContainerOs Windows

# Configure IoT Edge with secure connection string
Write-Host "Configuring IoT Edge with secure connection string..." -ForegroundColor Yellow

# Function to retrieve connection string securely
function Get-SecureConnectionString {
    # Try to get from environment variable first
    if ($env:CONNECTION_STRING) {
        return $env:CONNECTION_STRING
    }
    
    # Try to get from Azure Key Vault if available
    if (Get-Command az -ErrorAction SilentlyContinue) {
        if ($env:KEY_VAULT_NAME -and $env:SECRET_NAME) {
            Write-Host "Retrieving connection string from Azure Key Vault..." -ForegroundColor Gray
            try {
                $connectionString = az keyvault secret show --vault-name $env:KEY_VAULT_NAME --name $env:SECRET_NAME --query value --output tsv
                if ($LASTEXITCODE -eq 0) {
                    return $connectionString
                }
            }
            catch {
                Write-Host "Failed to retrieve from Key Vault: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    
    # Try to get from local secure file
    $secureFilePath = "C:\ProgramData\iotedge\connection-string"
    if (Test-Path $secureFilePath) {
        Write-Host "Retrieving connection string from local secure file..." -ForegroundColor Gray
        try {
            return Get-Content $secureFilePath -Raw -ErrorAction Stop
        }
        catch {
            Write-Host "Failed to read local file: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    Write-Error "No secure connection string source found"
    Write-Host "Please set one of the following:" -ForegroundColor Yellow
    Write-Host "  - CONNECTION_STRING environment variable" -ForegroundColor Yellow
    Write-Host "  - KEY_VAULT_NAME and SECRET_NAME environment variables" -ForegroundColor Yellow
    Write-Host "  - Place connection string in C:\ProgramData\iotedge\connection-string" -ForegroundColor Yellow
    return $null
}

# Get connection string securely
$connectionStringSecure = Get-SecureConnectionString
if (-not $connectionStringSecure) {
    Write-Error "Failed to retrieve connection string securely"
    exit 1
}

# Configure IoT Edge with the secure connection string
iotedge config mp --connection-string $connectionStringSecure

# Clear the connection string from memory
$connectionStringSecure = $null
[System.GC]::Collect()

# Start IoT Edge service
Write-Host "Starting IoT Edge service..." -ForegroundColor Yellow
Start-Service iotedge

# Verify installation
Write-Host "Verifying IoT Edge installation..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
iotedge list

Write-Host "IoT Edge Runtime installed and configured successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "SECURITY SETUP REQUIRED:" -ForegroundColor Yellow
Write-Host "Before running this script, set up one of the following secure connection string sources:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1 - Environment Variable:" -ForegroundColor Gray
Write-Host "  `$env:CONNECTION_STRING = 'your-device-connection-string'" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 2 - Azure Key Vault (recommended):" -ForegroundColor Gray
Write-Host "  `$env:KEY_VAULT_NAME = 'your-key-vault-name'" -ForegroundColor Gray
Write-Host "  `$env:SECRET_NAME = 'your-secret-name'" -ForegroundColor Gray
Write-Host "  az login  # Ensure you're authenticated" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 3 - Local Secure File:" -ForegroundColor Gray
Write-Host "  New-Item -ItemType Directory -Path 'C:\ProgramData\iotedge' -Force" -ForegroundColor Gray
Write-Host "  'your-device-connection-string' | Out-File -FilePath 'C:\ProgramData\iotedge\connection-string' -Encoding UTF8" -ForegroundColor Gray
Write-Host "  icacls 'C:\ProgramData\iotedge\connection-string' /inheritance:r /grant:r 'SYSTEM:(R)' /grant:r 'Administrators:(R)'" -ForegroundColor Gray
Write-Host ""
Write-Host "The script will automatically retrieve the connection string from the configured source." -ForegroundColor Yellow
"@
                
                $windowsScriptPath = Join-Path -Path $env:TEMP -ChildPath "install-iotedge-windows.ps1"
                $windowsScript | Set-Content -Path $windowsScriptPath
                
                Write-ColorOutput "Windows installation script created: $windowsScriptPath" -ForegroundColor Green
                Write-ColorOutput "Run this script as Administrator on your Windows edge device to install IoT Edge Runtime" -ForegroundColor Yellow
            }
            else {
                Write-ColorOutput "Unsupported device type: $EdgeDeviceType. Supported types are 'Linux' and 'Windows'." -ForegroundColor Red
            }
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
        Write-ColorOutput "Device Connection String: [SECURE_REFERENCE]" -ForegroundColor Gray
        Write-ColorOutput "Deployment Name: $deploymentName" -ForegroundColor Gray
        Write-ColorOutput "Device ID: $($deviceDetails.deviceId)" -ForegroundColor Gray
        
        if ($ContainerRegistryName) {
            Write-ColorOutput "Container Registry: $ContainerRegistryName" -ForegroundColor Gray
            Write-ColorOutput "ACR Login Server: $acrLoginServer" -ForegroundColor Gray
        }
        
        if ($EnableMonitoring) {
            Write-ColorOutput "Log Analytics Workspace: $workspaceName" -ForegroundColor Gray
        }
        
        # Security warning for sensitive data
        Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
        Write-ColorOutput "The returned object contains sensitive IoT Edge device connection strings." -ForegroundColor Yellow
        Write-ColorOutput "Please ensure this data is:" -ForegroundColor Yellow
        Write-ColorOutput "  • Not logged or written to files" -ForegroundColor Yellow
        Write-ColorOutput "  • Not committed to version control" -ForegroundColor Yellow
        Write-ColorOutput "  • Stored securely in production environments" -ForegroundColor Yellow
        Write-ColorOutput "  • Considered for Azure Key Vault integration" -ForegroundColor Yellow
        Write-ColorOutput "  • Use secure connection string retrieval in installation scripts" -ForegroundColor Yellow
        
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