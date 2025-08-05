function Configure-IoTEdgeModules {
    <#
    .SYNOPSIS
        Configures IoT Edge modules and settings.
    
    .DESCRIPTION
        Configures modules and settings for IoT Edge deployments,
        including updating application configuration files.
    
    .PARAMETER ResourceGroup
        The resource group name.
    
    .PARAMETER IoTHubName
        The IoT Hub name.
    
    .PARAMETER EdgeDeviceName
        The edge device name.
    
    .PARAMETER DeviceConnectionString
        The device connection string.
    
    .PARAMETER DeploymentName
        The deployment name.
    
    .PARAMETER ContainerRegistryName
        The container registry name.
    
    .PARAMETER ContainerRegistryLoginServer
        The container registry login server.
    
    .PARAMETER LogAnalyticsWorkspace
        The Log Analytics workspace name.
    
    .PARAMETER ProjectPath
        The path to the project to configure.
    
    .EXAMPLE
        Configure-IoTEdgeModules -ResourceGroup "my-rg" -IoTHubName "my-iothub" -EdgeDeviceName "my-edge-device"
    
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
        
        [Parameter(Mandatory = $true)]
        [string]$EdgeDeviceName,
        
        [Parameter(Mandatory = $false)]
        [string]$DeviceConnectionString,
        
        [Parameter(Mandatory = $false)]
        [string]$DeploymentName,
        
        [Parameter(Mandatory = $false)]
        [string]$ContainerRegistryName,
        
        [Parameter(Mandatory = $false)]
        [string]$ContainerRegistryLoginServer,
        
        [Parameter(Mandatory = $false)]
        [string]$LogAnalyticsWorkspace,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )
    
    try {
        Write-ColorOutput "Configuring IoT Edge modules..." -ForegroundColor Cyan
        
        # Validate Azure CLI availability
        if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
            throw "Azure CLI is not installed or not available in PATH. Please install Azure CLI from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        }
        
        # Check if user is authenticated
        try {
            $null = az account show --query id --output tsv 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "You are not logged in to Azure. Please run 'az login' to authenticate."
            }
        }
        catch {
            throw "Azure authentication failed. Please run 'az login' to authenticate with Azure."
        }
        
        # Helper function to mask sensitive connection strings
        function Get-MaskedConnectionString {
            param([string]$ConnectionString)
            if ([string]::IsNullOrEmpty($ConnectionString)) {
                return "[NOT SET]"
            }
            if ($ConnectionString.Length -le 8) {
                return "*" * $ConnectionString.Length
            }
            return "*" * ($ConnectionString.Length - 8) + $ConnectionString.Substring($ConnectionString.Length - 8)
        }
        
        # Get device connection string if not provided
        if (-not $DeviceConnectionString) {
            $DeviceConnectionString = az iot hub device-identity connection-string show `
                --hub-name $IoTHubName `
                --device-id $EdgeDeviceName `
                --query connectionString `
                --output tsv
        }
        
        # Get device details
        $deviceDetails = az iot hub device-identity show `
            --hub-name $IoTHubName `
            --device-id $EdgeDeviceName `
            --output json | ConvertFrom-Json
        
        # Get deployment details if not provided
        if (-not $DeploymentName) {
            $deployments = az iot edge deployment list `
                --hub-name $IoTHubName `
                --output json | ConvertFrom-Json
            
            if ($deployments.Count -gt 0) {
                $DeploymentName = $deployments[0].id
            }
        }
        
        # Get container registry details if not provided
        if ($ContainerRegistryName -and -not $ContainerRegistryLoginServer) {
            $ContainerRegistryLoginServer = az acr show `
                --name $ContainerRegistryName `
                --resource-group $ResourceGroup `
                --query loginServer `
                --output tsv
        }
        
        # Get Log Analytics workspace details if not provided
        if (-not $LogAnalyticsWorkspace) {
            $workspaces = az monitor log-analytics workspace list `
                --resource-group $ResourceGroup `
                --output json | ConvertFrom-Json
            
            if ($workspaces.Count -gt 0) {
                $LogAnalyticsWorkspace = $workspaces[0].name
            }
        }
        
        # Display connection information
        Write-ColorOutput "`nIoT Edge Device Information:" -ForegroundColor Green
        Write-ColorOutput "IoT Hub Name: $IoTHubName" -ForegroundColor Gray
        Write-ColorOutput "Edge Device Name: $EdgeDeviceName" -ForegroundColor Gray
        Write-ColorOutput "Device Connection String: $(Get-MaskedConnectionString -ConnectionString $DeviceConnectionString)" -ForegroundColor Gray
        Write-ColorOutput "Device ID: $($deviceDetails.deviceId)" -ForegroundColor Gray
        Write-ColorOutput "Device Status: $($deviceDetails.status)" -ForegroundColor Gray
        Write-ColorOutput "Deployment Name: $DeploymentName" -ForegroundColor Gray
        
        if ($ContainerRegistryName) {
            Write-ColorOutput "Container Registry: $ContainerRegistryName" -ForegroundColor Gray
            Write-ColorOutput "ACR Login Server: $ContainerRegistryLoginServer" -ForegroundColor Gray
        }
        
        if ($LogAnalyticsWorkspace) {
            Write-ColorOutput "Log Analytics Workspace: $LogAnalyticsWorkspace" -ForegroundColor Gray
        }
        
        # Update project configuration files if project path is provided
        if ($ProjectPath -and (Test-Path -Path $ProjectPath)) {
            Write-ColorOutput "`nUpdating project configuration files..." -ForegroundColor Yellow
            
            # Update appsettings.json for .NET projects
            $appSettingsPath = Join-Path -Path $ProjectPath -ChildPath "appsettings.json"
            if (Test-Path -Path $appSettingsPath) {
                Write-ColorOutput "Updating appsettings.json..." -ForegroundColor Gray
                $appSettings = Get-Content -Path $appSettingsPath | ConvertFrom-Json
                
                if (-not $appSettings.IoTEdge) {
                    $appSettings | Add-Member -MemberType NoteProperty -Name "IoTEdge" -Value @{}
                }
                
                $appSettings.IoTEdge.IoTHubName = $IoTHubName
                $appSettings.IoTEdge.EdgeDeviceName = $EdgeDeviceName
                $appSettings.IoTEdge.DeviceConnectionString = $DeviceConnectionString
                $appSettings.IoTEdge.DeploymentName = $DeploymentName
                $appSettings.IoTEdge.ContainerRegistryName = $ContainerRegistryName
                $appSettings.IoTEdge.ContainerRegistryLoginServer = $ContainerRegistryLoginServer
                $appSettings.IoTEdge.LogAnalyticsWorkspace = $LogAnalyticsWorkspace
                $appSettings.IoTEdge.DeviceId = $deviceDetails.deviceId
                $appSettings.IoTEdge.DeviceStatus = $deviceDetails.status
                
                # Validate JSON structure before writing with atomic write
                try {
                    $jsonString = $appSettings | ConvertTo-Json -Depth 10
                    $validatedJson = $jsonString | ConvertFrom-Json
                    
                    # Atomic write to appsettings.json
                    $tempAppSettingsPath = $appSettingsPath + ".tmp"
                    try {
                        $validatedJson | ConvertTo-Json -Depth 10 | Set-Content -Path $tempAppSettingsPath -ErrorAction Stop
                        Move-Item -Path $tempAppSettingsPath -Destination $appSettingsPath -Force
                        Write-ColorOutput "Updated appsettings.json" -ForegroundColor Green
                        Write-ColorOutput "⚠️  Note: appsettings.json contains sensitive IoT Edge connection strings - ensure it's not committed to version control" -ForegroundColor Yellow
                    }
                    catch {
                        if (Test-Path -Path $tempAppSettingsPath) {
                            Remove-Item -Path $tempAppSettingsPath -Force -ErrorAction SilentlyContinue
                        }
                        throw
                    }
                }
                catch {
                    throw "Invalid JSON structure generated. Cannot save appsettings.json: $($_.Exception.Message)"
                }
            }
            
            # Update package.json for Node.js projects
            $packageJsonPath = Join-Path -Path $ProjectPath -ChildPath "package.json"
            if (Test-Path -Path $packageJsonPath) {
                Write-ColorOutput "Updating package.json..." -ForegroundColor Gray
                $packageJson = Get-Content -Path $packageJsonPath | ConvertFrom-Json
                
                if (-not $packageJson.config) {
                    $packageJson | Add-Member -MemberType NoteProperty -Name "config" -Value @{}
                }
                
                $packageJson.config.iotEdgeIoTHubName = $IoTHubName
                $packageJson.config.iotEdgeDeviceName = $EdgeDeviceName
                $packageJson.config.iotEdgeDeviceConnectionString = $DeviceConnectionString
                $packageJson.config.iotEdgeDeploymentName = $DeploymentName
                $packageJson.config.iotEdgeContainerRegistryName = $ContainerRegistryName
                $packageJson.config.iotEdgeContainerRegistryLoginServer = $ContainerRegistryLoginServer
                $packageJson.config.iotEdgeLogAnalyticsWorkspace = $LogAnalyticsWorkspace
                $packageJson.config.iotEdgeDeviceId = $deviceDetails.deviceId
                $packageJson.config.iotEdgeDeviceStatus = $deviceDetails.status
                
                # Validate JSON structure before writing with atomic write
                try {
                    $jsonString = $packageJson | ConvertTo-Json -Depth 10
                    $validatedJson = $jsonString | ConvertFrom-Json
                    
                    # Atomic write to package.json
                    $tempPackageJsonPath = $packageJsonPath + ".tmp"
                    try {
                        $validatedJson | ConvertTo-Json -Depth 10 | Set-Content -Path $tempPackageJsonPath -ErrorAction Stop
                        Move-Item -Path $tempPackageJsonPath -Destination $packageJsonPath -Force
                        Write-ColorOutput "Updated package.json" -ForegroundColor Green
                        Write-ColorOutput "⚠️  Note: package.json contains sensitive IoT Edge connection strings - ensure it's not committed to version control" -ForegroundColor Yellow
                    }
                    catch {
                        if (Test-Path -Path $tempPackageJsonPath) {
                            Remove-Item -Path $tempPackageJsonPath -Force -ErrorAction SilentlyContinue
                        }
                        throw
                    }
                }
                catch {
                    throw "Invalid JSON structure generated. Cannot save package.json: $($_.Exception.Message)"
                }
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            
            # Enhanced security warning for sensitive data
            Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
            Write-ColorOutput "The .env file will contain sensitive IoT Edge connection strings and credentials." -ForegroundColor Yellow
            Write-ColorOutput "These connection strings provide access to your IoT Hub and should be protected." -ForegroundColor Yellow
            Write-ColorOutput "For production environments, consider using Azure Key Vault for secure storage." -ForegroundColor Yellow
            Write-ColorOutput "Ensure .env is added to .gitignore to prevent accidental commits to version control." -ForegroundColor Yellow
            Write-ColorOutput "File location: $envPath" -ForegroundColor Gray
            
            # Check if .gitignore exists and contains .env
            $gitignorePath = Join-Path -Path $ProjectPath -ChildPath ".gitignore"
            if (Test-Path -Path $gitignorePath) {
                $gitignoreContent = Get-Content -Path $gitignorePath
                if ($gitignoreContent -notcontains ".env") {
                    Write-ColorOutput "Adding .env to .gitignore for security..." -ForegroundColor Cyan
                    Add-Content -Path $gitignorePath -Value "`n# Environment variables with sensitive data`n.env"
                }
            }
            else {
                Write-ColorOutput "Creating .gitignore file with .env exclusion..." -ForegroundColor Cyan
                @"
# Environment variables with sensitive data
.env

# Other common exclusions
node_modules/
*.log
.DS_Store
"@ | Set-Content -Path $gitignorePath
            }
            
            # Create temporary file for atomic write
            $tempEnvPath = $envPath + ".tmp"
            
            try {
                @"
# Azure IoT Edge Configuration
AZURE_IOT_EDGE_IOT_HUB_NAME=$IoTHubName
AZURE_IOT_EDGE_DEVICE_NAME=$EdgeDeviceName
AZURE_IOT_EDGE_DEVICE_CONNECTION_STRING=$DeviceConnectionString
AZURE_IOT_EDGE_DEPLOYMENT_NAME=$DeploymentName
AZURE_IOT_EDGE_CONTAINER_REGISTRY_NAME=$ContainerRegistryName
AZURE_IOT_EDGE_CONTAINER_REGISTRY_LOGIN_SERVER=$ContainerRegistryLoginServer
AZURE_IOT_EDGE_LOG_ANALYTICS_WORKSPACE=$LogAnalyticsWorkspace
AZURE_IOT_EDGE_DEVICE_ID=$($deviceDetails.deviceId)
AZURE_IOT_EDGE_DEVICE_STATUS=$($deviceDetails.status)
"@ | Set-Content -Path $tempEnvPath -ErrorAction Stop
                
                # Atomic move to replace original file
                Move-Item -Path $tempEnvPath -Destination $envPath -Force
                Write-ColorOutput "Created .env file" -ForegroundColor Green
            }
            catch {
                # Clean up temporary file if it exists
                if (Test-Path -Path $tempEnvPath) {
                    Remove-Item -Path $tempEnvPath -Force -ErrorAction SilentlyContinue
                }
                throw "Failed to create .env file: $($_.Exception.Message)"
            }
        }
        
        # Save connection information to a configuration file
        $userProfile = [Environment]::GetFolderPath('UserProfile')
        $configPath = Join-Path -Path $userProfile -ChildPath ".homelab\iotedge-connections.json"
        $configDir = Split-Path -Path $configPath -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $connectionConfig = @{
            ResourceGroup                = $ResourceGroup
            IoTHubName                   = $IoTHubName
            EdgeDeviceName               = $EdgeDeviceName
            DeviceConnectionString       = $DeviceConnectionString
            DeploymentName               = $DeploymentName
            ContainerRegistryName        = $ContainerRegistryName
            ContainerRegistryLoginServer = $ContainerRegistryLoginServer
            LogAnalyticsWorkspace        = $LogAnalyticsWorkspace
            DeviceId                     = $deviceDetails.deviceId
            DeviceStatus                 = $deviceDetails.status
            CreatedAt                    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        try {
            $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath -ErrorAction Stop
            Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
            Write-ColorOutput "⚠️  Note: Connection config contains sensitive IoT Edge connection strings - ensure file is protected" -ForegroundColor Yellow
        }
        catch {
            Write-ColorOutput "Error saving connection configuration: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to save connection configuration: $($_.Exception.Message)"
        }
        
        Write-ColorOutput "`nIoT Edge modules configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring IoT Edge modules: $_" -ForegroundColor Red
        throw
    }
} 