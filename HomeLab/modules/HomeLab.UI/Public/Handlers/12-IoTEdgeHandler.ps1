function Invoke-IoTEdgeHandler {
    <#
    .SYNOPSIS
        Handles IoT and edge computing deployment menu commands.
    
    .DESCRIPTION
        This function processes commands from the IoT and edge computing deployment menu.
    
    .PARAMETER Command
        The command to process.
    
    .EXAMPLE
        Invoke-IoTEdgeHandler -Command "Deploy-AzureIoTHub"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    # Import required modules
    try {
        Import-Module HomeLab.Core -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to import HomeLab.Core module: $_"
        return
    }
    
    try {
        Import-Module HomeLab.Azure -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to import HomeLab.Azure module: $_"
        return
    }
    
    # Get configuration
    try {
        $config = Get-Configuration -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to retrieve configuration: $_"
        return
    }
    
    # Helper function to get project path
    function Get-ProjectPathForIoTEdge {
        # Use script-level variable instead of global
        $script:SelectedProjectPath = $script:SelectedProjectPath ?? $null
        
        # Check if a project has already been selected
        if ($script:SelectedProjectPath -and (Test-Path -Path $script:SelectedProjectPath)) {
            $useSelectedPath = Read-Host "Use previously selected project ($script:SelectedProjectPath)? (y/n)"
            
            if ($useSelectedPath -eq "y") {
                $projectPath = $script:SelectedProjectPath
                Write-Host "Using selected project folder: $projectPath" -ForegroundColor Green
                return $projectPath
            }
        }
        
        Write-Host "`nSelect the project folder for IoT/Edge deployment..." -ForegroundColor Yellow
        $projectPath = Select-ProjectFolder
        
        if (-not $projectPath) {
            Write-Host "No folder selected. Deployment canceled." -ForegroundColor Red
            return $null
        }
        
        Write-Host "Selected project folder: $projectPath" -ForegroundColor Green
        return $projectPath
    }
    
    switch ($Command) {
        "Browse-Project" {
            Clear-Host
            Write-Host "=== Browse and Select Project for IoT & Edge Computing ===" -ForegroundColor Cyan
            
            Write-Host "`nSelect a project folder..." -ForegroundColor Yellow
            $projectPath = Select-ProjectFolder
            
            if (-not $projectPath) {
                Write-Host "No folder selected." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            Write-Host "`nSelected project folder: $projectPath" -ForegroundColor Green
            
            # Analyze project structure for IoT/Edge requirements
            Write-Host "`nAnalyzing project structure for IoT/Edge requirements..." -ForegroundColor Yellow
            
            $projectInfo = @{
                Path               = $projectPath
                Files              = @(Get-ChildItem -Path $projectPath -File | Select-Object -ExpandProperty Name)
                Folders            = @(Get-ChildItem -Path $projectPath -Directory | Select-Object -ExpandProperty Name)
                HasPackageJson     = Test-Path -Path "$projectPath\package.json"
                HasRequirementsTxt = Test-Path -Path "$projectPath\requirements.txt"
                HasWebConfig       = Test-Path -Path "$projectPath\web.config"
                HasAppSettings     = Test-Path -Path "$projectPath\appsettings.json"
                HasDockerfile      = Test-Path -Path "$projectPath\Dockerfile"
                HasDockerCompose   = Test-Path -Path "$projectPath\docker-compose.yml"
                HasIoTHubConfig    = Test-Path -Path "$projectPath\iothub-config.json"
                HasEdgeModule      = Test-Path -Path "$projectPath\modules\"
                HasDeviceConfig    = Test-Path -Path "$projectPath\device-config.json"
                HasSensorCode      = Test-Path -Path "$projectPath\*.ino" -or Test-Path -Path "$projectPath\*.cpp"
                HasPythonFiles     = Test-Path -Path "$projectPath\*.py"
                HasNodeFiles       = Test-Path -Path "$projectPath\*.js" -or Test-Path -Path "$projectPath\*.ts"
            }
            
            # Display project analysis
            Write-Host "`nProject Analysis:" -ForegroundColor Cyan
            Write-Host "  Path: $($projectInfo.Path)" -ForegroundColor Gray
            Write-Host "  Node.js Project: $($projectInfo.HasPackageJson)" -ForegroundColor Gray
            Write-Host "  Python Project: $($projectInfo.HasRequirementsTxt)" -ForegroundColor Gray
            Write-Host "  .NET Project: $($projectInfo.HasWebConfig)" -ForegroundColor Gray
            Write-Host "  IoT Hub Config: $($projectInfo.HasIoTHubConfig)" -ForegroundColor Gray
            Write-Host "  Edge Modules: $($projectInfo.HasEdgeModule)" -ForegroundColor Gray
            Write-Host "  Device Config: $($projectInfo.HasDeviceConfig)" -ForegroundColor Gray
            Write-Host "  Sensor Code: $($projectInfo.HasSensorCode)" -ForegroundColor Gray
            Write-Host "  Python Files: $($projectInfo.HasPythonFiles)" -ForegroundColor Gray
            Write-Host "  Node.js Files: $($projectInfo.HasNodeFiles)" -ForegroundColor Gray
            
            # Suggest IoT/Edge services based on project analysis
            Write-Host "`nSuggested IoT & Edge Services:" -ForegroundColor Cyan
            if ($projectInfo.HasIoTHubConfig -or $projectInfo.HasDeviceConfig) {
                Write-Host "  • Azure IoT Hub for device connectivity and management" -ForegroundColor Green
                Write-Host "  • Azure IoT Edge Runtime for edge computing" -ForegroundColor Green
                Write-Host "  • Azure IoT Central for device management" -ForegroundColor Green
            }
            if ($projectInfo.HasEdgeModule -or $projectInfo.HasDockerfile) {
                Write-Host "  • Azure IoT Edge Runtime for containerized edge modules" -ForegroundColor Green
                Write-Host "  • Edge Computing Cluster for distributed processing" -ForegroundColor Green
            }
            if ($projectInfo.HasSensorCode) {
                Write-Host "  • Azure IoT Hub for sensor data collection" -ForegroundColor Green
                Write-Host "  • Azure Digital Twins for physical environment modeling" -ForegroundColor Green
                Write-Host "  • Azure Sphere for secure IoT devices" -ForegroundColor Green
            }
            if ($projectInfo.HasPythonFiles -or $projectInfo.HasNodeFiles) {
                Write-Host "  • Azure IoT Hub for application connectivity" -ForegroundColor Green
                Write-Host "  • AWS IoT Core for cross-platform IoT" -ForegroundColor Green
                Write-Host "  • Google Cloud IoT Core for cloud-native IoT" -ForegroundColor Green
            }
            if ($projectInfo.HasDockerCompose) {
                Write-Host "  • Edge Computing Cluster for multi-container deployments" -ForegroundColor Green
                Write-Host "  • AWS Greengrass for edge computing" -ForegroundColor Green
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureIoTHub" {
            Clear-Host
            Write-Host "=== Deploy Azure IoT Hub ===" -ForegroundColor Cyan
            Write-Host "Deploys Azure IoT Hub for device connectivity and management" -ForegroundColor Gray
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-IoTEdgeDeploymentParameters -DeploymentType "azureiothub" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy Azure IoT Hub with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying Azure IoT Hub..." -Activity "Step 2/4"
            Write-Host "`nDeploying Azure IoT Hub..." -ForegroundColor Yellow
            
            try {
                Deploy-AzureIoTHub @params
                Update-ProgressBar -PercentComplete 75 -Status "IoT Hub deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAzure IoT Hub deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4"
                Write-Host "`nError deploying Azure IoT Hub: $_" -ForegroundColor Red
            }
            
            # Step 3: Configure IoT Hub endpoints
            Update-ProgressBar -PercentComplete 90 -Status "Configuring IoT Hub endpoints..." -Activity "Step 4/4"
            Write-Host "`nConfiguring IoT Hub endpoints..." -ForegroundColor Yellow
            
            try {
                Configure-IoTHubEndpoints @params
                Write-Host "IoT Hub endpoints configured successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "Warning: Could not configure IoT Hub endpoints: $_" -ForegroundColor Yellow
            }
            
            Update-ProgressBar -PercentComplete 100 -Status "Deployment completed!" -Activity "Step 4/4"
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureIoTEdgeRuntime" {
            Clear-Host
            Write-Host "=== Deploy Azure IoT Edge Runtime ===" -ForegroundColor Cyan
            Write-Host "Deploys Azure IoT Edge Runtime for edge computing" -ForegroundColor Gray
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-IoTEdgeDeploymentParameters -DeploymentType "azureiotedge" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy Azure IoT Edge Runtime with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying Azure IoT Edge Runtime..." -Activity "Step 2/4"
            Write-Host "`nDeploying Azure IoT Edge Runtime..." -ForegroundColor Yellow
            
            try {
                Deploy-AzureIoTEdgeRuntime @params
                Update-ProgressBar -PercentComplete 75 -Status "IoT Edge Runtime deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAzure IoT Edge Runtime deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4"
                Write-Host "`nError deploying Azure IoT Edge Runtime: $_" -ForegroundColor Red
            }
            
            # Step 3: Configure edge modules
            Update-ProgressBar -PercentComplete 90 -Status "Configuring edge modules..." -Activity "Step 4/4"
            Write-Host "`nConfiguring edge modules..." -ForegroundColor Yellow
            
            try {
                Configure-IoTEdgeModules @params
                Write-Host "Edge modules configured successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "Warning: Could not configure edge modules: $_" -ForegroundColor Yellow
            }
            
            Update-ProgressBar -PercentComplete 100 -Status "Deployment completed!" -Activity "Step 4/4"
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureIoTCentral" {
            Clear-Host
            Write-Host "=== Deploy Azure IoT Central ===" -ForegroundColor Cyan
            Write-Host "Deploys Azure IoT Central for device management" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Azure IoT Central deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureDigitalTwins" {
            Clear-Host
            Write-Host "=== Deploy Azure Digital Twins ===" -ForegroundColor Cyan
            Write-Host "Deploys Azure Digital Twins for physical environment modeling" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Azure Digital Twins deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureSphere" {
            Clear-Host
            Write-Host "=== Deploy Azure Sphere ===" -ForegroundColor Cyan
            Write-Host "Deploys Azure Sphere for secure IoT devices" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Azure Sphere deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AWSIoTCore" {
            Clear-Host
            Write-Host "=== Deploy AWS IoT Core ===" -ForegroundColor Cyan
            Write-Host "Deploys AWS IoT Core for device connectivity" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 AWS IoT Core deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AWSGreengrass" {
            Clear-Host
            Write-Host "=== Deploy AWS Greengrass ===" -ForegroundColor Cyan
            Write-Host "Deploys AWS Greengrass for edge computing" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 AWS Greengrass deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-GCPIoTCore" {
            Clear-Host
            Write-Host "=== Deploy Google Cloud IoT Core ===" -ForegroundColor Cyan
            Write-Host "Deploys Google Cloud IoT Core for device management" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Google Cloud IoT Core deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-EdgeComputingCluster" {
            Clear-Host
            Write-Host "=== Deploy Edge Computing Cluster ===" -ForegroundColor Cyan
            Write-Host "Deploys edge computing cluster for distributed processing" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Edge Computing Cluster deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AutoDetectIoTServices" {
            Clear-Host
            Write-Host "=== Auto-Detect and Deploy IoT Services ===" -ForegroundColor Cyan
            Write-Host "Automatically detects and deploys appropriate IoT services" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Auto-detection for IoT services coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Configure-IoTDeviceManagement" {
            Clear-Host
            Write-Host "=== Configure IoT Device Management ===" -ForegroundColor Cyan
            Write-Host "Configures device management and monitoring settings" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 IoT device management configuration coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Show-IoTEdgeServiceTypeInfo" {
            Clear-Host
            Write-Host "=== IoT & Edge Computing Service Type Information ===" -ForegroundColor Cyan
            Write-Host ""
            
            Write-Host "🔌 IoT Services:" -ForegroundColor White
            Write-Host "  • Azure IoT Hub: Device connectivity and message routing" -ForegroundColor Gray
            Write-Host "  • Azure IoT Central: SaaS solution for device management" -ForegroundColor Gray
            Write-Host "  • Azure Digital Twins: Physical environment modeling" -ForegroundColor Gray
            Write-Host "  • Azure Sphere: Secure IoT device platform" -ForegroundColor Gray
            Write-Host "  • AWS IoT Core: Device connectivity and management" -ForegroundColor Gray
            Write-Host "  • Google Cloud IoT Core: Device management and data ingestion" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "⚡ Edge Computing Services:" -ForegroundColor White
            Write-Host "  • Azure IoT Edge Runtime: Containerized edge computing" -ForegroundColor Gray
            Write-Host "  • AWS Greengrass: Edge computing and local processing" -ForegroundColor Gray
            Write-Host "  • Edge Computing Cluster: Distributed edge processing" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🔗 Use Cases:" -ForegroundColor White
            Write-Host "  • IoT Hub: Sensor data collection, device telemetry, command control" -ForegroundColor Gray
            Write-Host "  • IoT Edge: Local data processing, offline operation, edge AI" -ForegroundColor Gray
            Write-Host "  • IoT Central: Rapid IoT solution development, device templates" -ForegroundColor Gray
            Write-Host "  • Digital Twins: Building automation, smart cities, industrial IoT" -ForegroundColor Gray
            Write-Host "  • Edge Computing: Real-time processing, low-latency applications" -ForegroundColor Gray
            Write-Host "  • Device Management: Remote monitoring, firmware updates, security" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "List-DeployedIoTEdgeServices" {
            Clear-Host
            Write-Host "=== List Deployed IoT & Edge Computing Services ===" -ForegroundColor Cyan
            Write-Host "Shows all deployed IoT and edge computing resources" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 IoT/Edge service listing coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        default {
            Write-Host "Unknown command: $Command" -ForegroundColor Red
            Start-Sleep 2
        }
    }
} 