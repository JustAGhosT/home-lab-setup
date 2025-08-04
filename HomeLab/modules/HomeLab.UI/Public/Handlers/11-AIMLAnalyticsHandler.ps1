function Invoke-AIMLAnalyticsHandler {
    <#
    .SYNOPSIS
        Handles AI/ML and analytics deployment menu commands.
    
    .DESCRIPTION
        This function processes commands from the AI/ML and analytics deployment menu.
    
    .PARAMETER Command
        The command to process.
    
    .EXAMPLE
        Invoke-AIMLAnalyticsHandler -Command "Deploy-AzureCognitiveServices"
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
    function Get-ProjectPathForAIMLAnalytics {
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
        
        Write-Host "`nSelect the project folder for AI/ML deployment..." -ForegroundColor Yellow
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
            Write-Host "=== Browse and Select Project for AI/ML & Analytics ===" -ForegroundColor Cyan
            
            Write-Host "`nSelect a project folder..." -ForegroundColor Yellow
            $projectPath = Select-ProjectFolder
            
            if (-not $projectPath) {
                Write-Host "No folder selected." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            Write-Host "`nSelected project folder: $projectPath" -ForegroundColor Green
            
            # Analyze project structure for AI/ML requirements
            Write-Host "`nAnalyzing project structure for AI/ML requirements..." -ForegroundColor Yellow
            
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
                HasJupyterNotebook = Test-Path -Path "$projectPath\*.ipynb"
                HasPythonFiles     = Test-Path -Path "$projectPath\*.py"
                HasTensorFlow      = Test-Path -Path "$projectPath\requirements.txt" -and (Get-Content "$projectPath\requirements.txt" | Select-String "tensorflow")
                HasPyTorch         = Test-Path -Path "$projectPath\requirements.txt" -and (Get-Content "$projectPath\requirements.txt" | Select-String "torch")
                HasScikitLearn     = Test-Path -Path "$projectPath\requirements.txt" -and (Get-Content "$projectPath\requirements.txt" | Select-String "scikit-learn")
            }
            
            # Display project analysis
            Write-Host "`nProject Analysis:" -ForegroundColor Cyan
            Write-Host "  Path: $($projectInfo.Path)" -ForegroundColor Gray
            Write-Host "  Node.js Project: $($projectInfo.HasPackageJson)" -ForegroundColor Gray
            Write-Host "  Python Project: $($projectInfo.HasRequirementsTxt)" -ForegroundColor Gray
            Write-Host "  .NET Project: $($projectInfo.HasWebConfig)" -ForegroundColor Gray
            Write-Host "  Jupyter Notebooks: $($projectInfo.HasJupyterNotebook)" -ForegroundColor Gray
            Write-Host "  Python Files: $($projectInfo.HasPythonFiles)" -ForegroundColor Gray
            Write-Host "  TensorFlow: $($projectInfo.HasTensorFlow)" -ForegroundColor Gray
            Write-Host "  PyTorch: $($projectInfo.HasPyTorch)" -ForegroundColor Gray
            Write-Host "  Scikit-learn: $($projectInfo.HasScikitLearn)" -ForegroundColor Gray
            
            # Suggest AI/ML services based on project analysis
            Write-Host "`nSuggested AI/ML Services:" -ForegroundColor Cyan
            if ($projectInfo.HasPythonFiles -or $projectInfo.HasJupyterNotebook) {
                Write-Host "  • Azure Machine Learning Studio for Python ML models" -ForegroundColor Green
                Write-Host "  • Azure Cognitive Services for pre-built AI capabilities" -ForegroundColor Green
                Write-Host "  • Azure Stream Analytics for real-time data processing" -ForegroundColor Green
            }
            if ($projectInfo.HasTensorFlow -or $projectInfo.HasPyTorch) {
                Write-Host "  • Azure Machine Learning for deep learning models" -ForegroundColor Green
                Write-Host "  • AWS SageMaker for ML model training and deployment" -ForegroundColor Green
            }
            if ($projectInfo.HasPackageJson) {
                Write-Host "  • Azure Cognitive Services for Node.js applications" -ForegroundColor Green
                Write-Host "  • Google Cloud Vision API for image processing" -ForegroundColor Green
            }
            if ($projectInfo.HasWebConfig) {
                Write-Host "  • Azure Cognitive Services for .NET applications" -ForegroundColor Green
                Write-Host "  • Azure Data Factory for data orchestration" -ForegroundColor Green
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureCognitiveServices" {
            Clear-Host
            Write-Host "=== Deploy Azure Cognitive Services ===" -ForegroundColor Cyan
            Write-Host "Deploys Azure Cognitive Services for AI capabilities" -ForegroundColor Gray
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-AIMLDeploymentParameters -DeploymentType "azurecognitive" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy Azure Cognitive Services with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying Azure Cognitive Services..." -Activity "Step 2/4"
            Write-Host "`nDeploying Azure Cognitive Services..." -ForegroundColor Yellow
            
            try {
                Deploy-AzureCognitiveServices @params
                Update-ProgressBar -PercentComplete 75 -Status "Cognitive Services deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAzure Cognitive Services deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4"
                Write-Host "`nError deploying Azure Cognitive Services: $_" -ForegroundColor Red
            }
            
            # Step 3: Configure service endpoints
            Update-ProgressBar -PercentComplete 90 -Status "Configuring service endpoints..." -Activity "Step 4/4"
            Write-Host "`nConfiguring service endpoints..." -ForegroundColor Yellow
            
            try {
                Configure-CognitiveServicesEndpoints @params
                Write-Host "Service endpoints configured successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "Warning: Could not configure service endpoints: $_" -ForegroundColor Yellow
            }
            
            Update-ProgressBar -PercentComplete 100 -Status "Deployment completed!" -Activity "Step 4/4"
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureMachineLearningStudio" {
            Clear-Host
            Write-Host "=== Deploy Azure Machine Learning Studio ===" -ForegroundColor Cyan
            Write-Host "Deploys Azure Machine Learning Studio workspace" -ForegroundColor Gray
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-AIMLDeploymentParameters -DeploymentType "azureml" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy Azure ML Studio with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying Azure Machine Learning Studio..." -Activity "Step 2/4"
            Write-Host "`nDeploying Azure Machine Learning Studio..." -ForegroundColor Yellow
            
            try {
                Deploy-AzureMachineLearningStudio @params
                Update-ProgressBar -PercentComplete 75 -Status "ML Studio deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAzure Machine Learning Studio deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4"
                Write-Host "`nError deploying Azure Machine Learning Studio: $_" -ForegroundColor Red
            }
            
            # Step 3: Configure ML workspace
            Update-ProgressBar -PercentComplete 90 -Status "Configuring ML workspace..." -Activity "Step 4/4"
            Write-Host "`nConfiguring ML workspace..." -ForegroundColor Yellow
            
            try {
                Configure-MLWorkspace @params
                Write-Host "ML workspace configured successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "Warning: Could not configure ML workspace: $_" -ForegroundColor Yellow
            }
            
            Update-ProgressBar -PercentComplete 100 -Status "Deployment completed!" -Activity "Step 4/4"
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureStreamAnalytics" {
            Clear-Host
            Write-Host "=== Deploy Azure Stream Analytics ===" -ForegroundColor Cyan
            Write-Host "Deploys Azure Stream Analytics for real-time data processing" -ForegroundColor Gray
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-AIMLDeploymentParameters -DeploymentType "azurestreamanalytics" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy Azure Stream Analytics with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying Azure Stream Analytics..." -Activity "Step 2/4"
            Write-Host "`nDeploying Azure Stream Analytics..." -ForegroundColor Yellow
            
            try {
                Deploy-AzureStreamAnalytics @params
                Update-ProgressBar -PercentComplete 75 -Status "Stream Analytics deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAzure Stream Analytics deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4"
                Write-Host "`nError deploying Azure Stream Analytics: $_" -ForegroundColor Red
            }
            
            # Step 3: Configure streaming jobs
            Update-ProgressBar -PercentComplete 90 -Status "Configuring streaming jobs..." -Activity "Step 4/4"
            Write-Host "`nConfiguring streaming jobs..." -ForegroundColor Yellow
            
            try {
                Configure-StreamAnalyticsJobs @params
                Write-Host "Streaming jobs configured successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "Warning: Could not configure streaming jobs: $_" -ForegroundColor Yellow
            }
            
            Update-ProgressBar -PercentComplete 100 -Status "Deployment completed!" -Activity "Step 4/4"
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureDataFactory" {
            Clear-Host
            Write-Host "=== Deploy Azure Data Factory ===" -ForegroundColor Cyan
            Write-Host "Deploys Azure Data Factory for data orchestration" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Azure Data Factory deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureSynapseAnalytics" {
            Clear-Host
            Write-Host "=== Deploy Azure Synapse Analytics ===" -ForegroundColor Cyan
            Write-Host "Deploys Azure Synapse Analytics for big data processing" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Azure Synapse Analytics deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AWSSageMaker" {
            Clear-Host
            Write-Host "=== Deploy AWS SageMaker ===" -ForegroundColor Cyan
            Write-Host "Deploys AWS SageMaker for machine learning" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 AWS SageMaker deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AWSComprehend" {
            Clear-Host
            Write-Host "=== Deploy AWS Comprehend ===" -ForegroundColor Cyan
            Write-Host "Deploys AWS Comprehend for natural language processing" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 AWS Comprehend deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AWSRekognition" {
            Clear-Host
            Write-Host "=== Deploy AWS Rekognition ===" -ForegroundColor Cyan
            Write-Host "Deploys AWS Rekognition for computer vision" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 AWS Rekognition deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-GCPAIPlatform" {
            Clear-Host
            Write-Host "=== Deploy Google Cloud AI Platform ===" -ForegroundColor Cyan
            Write-Host "Deploys Google Cloud AI Platform for machine learning" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Google Cloud AI Platform deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-GCPVisionAPI" {
            Clear-Host
            Write-Host "=== Deploy Google Cloud Vision API ===" -ForegroundColor Cyan
            Write-Host "Deploys Google Cloud Vision API for image analysis" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Google Cloud Vision API deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AutoDetectAIMLServices" {
            Clear-Host
            Write-Host "=== Auto-Detect and Deploy AI/ML Services ===" -ForegroundColor Cyan
            Write-Host "Automatically detects and deploys appropriate AI/ML services" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Auto-detection for AI/ML services coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Configure-AIMLModelEndpoints" {
            Clear-Host
            Write-Host "=== Configure AI/ML Model Endpoints ===" -ForegroundColor Cyan
            Write-Host "Configures model endpoints and deployment settings" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 AI/ML model endpoint configuration coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Show-AIMLServiceTypeInfo" {
            Clear-Host
            Write-Host "=== AI/ML & Analytics Service Type Information ===" -ForegroundColor Cyan
            Write-Host ""
            
            Write-Host "🤖 AI/ML Services:" -ForegroundColor White
            Write-Host "  • Azure Cognitive Services: Pre-built AI capabilities (Vision, Speech, Language)" -ForegroundColor Gray
            Write-Host "  • Azure Machine Learning Studio: Drag-and-drop ML model development" -ForegroundColor Gray
            Write-Host "  • AWS SageMaker: End-to-end ML platform for training and deployment" -ForegroundColor Gray
            Write-Host "  • AWS Comprehend: Natural language processing service" -ForegroundColor Gray
            Write-Host "  • Google Cloud AI Platform: ML model training and deployment" -ForegroundColor Gray
            Write-Host "  • Google Cloud Vision API: Image analysis and recognition" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "📊 Analytics Services:" -ForegroundColor White
            Write-Host "  • Azure Stream Analytics: Real-time data stream processing" -ForegroundColor Gray
            Write-Host "  • Azure Data Factory: Data orchestration and ETL pipelines" -ForegroundColor Gray
            Write-Host "  • Azure Synapse Analytics: Big data processing and analytics" -ForegroundColor Gray
            Write-Host "  • AWS Rekognition: Computer vision and image analysis" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🔗 Use Cases:" -ForegroundColor White
            Write-Host "  • Cognitive Services: Chatbots, image recognition, speech-to-text" -ForegroundColor Gray
            Write-Host "  • Machine Learning: Predictive analytics, recommendation systems" -ForegroundColor Gray
            Write-Host "  • Stream Analytics: IoT data processing, real-time dashboards" -ForegroundColor Gray
            Write-Host "  • Data Factory: Data integration, ETL workflows, data pipelines" -ForegroundColor Gray
            Write-Host "  • Computer Vision: Image classification, object detection, OCR" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "List-DeployedAIMLServices" {
            Clear-Host
            Write-Host "=== List Deployed AI/ML & Analytics Services ===" -ForegroundColor Cyan
            Write-Host "Shows all deployed AI/ML and analytics resources" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 AI/ML service listing coming soon!" -ForegroundColor Yellow
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