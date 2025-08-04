function Invoke-DatabaseStorageHandler {
    <#
    .SYNOPSIS
        Handles database and storage deployment menu commands.
    
    .DESCRIPTION
        This function processes commands from the database and storage deployment menu.
    
    .PARAMETER Command
        The command to process.
    
    .EXAMPLE
        Invoke-DatabaseStorageHandler -Command "Deploy-AzureSQLDatabase"
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
    function Get-ProjectPathForDatabaseStorage {
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
        
        Write-Host "`nSelect the project folder for database/storage deployment..." -ForegroundColor Yellow
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
            Write-Host "=== Browse and Select Project for Database/Storage ===" -ForegroundColor Cyan
            
            Write-Host "`nSelect a project folder..." -ForegroundColor Yellow
            $projectPath = Select-ProjectFolder
            
            if (-not $projectPath) {
                Write-Host "No folder selected." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            Write-Host "`nSelected project folder: $projectPath" -ForegroundColor Green
            
            # Analyze project structure for database/storage requirements
            Write-Host "`nAnalyzing project structure for database/storage requirements..." -ForegroundColor Yellow
            
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
            }
            
            # Display project analysis
            Write-Host "`nProject Analysis:" -ForegroundColor Cyan
            Write-Host "  Path: $($projectInfo.Path)" -ForegroundColor Gray
            Write-Host "  Node.js Project: $($projectInfo.HasPackageJson)" -ForegroundColor Gray
            Write-Host "  Python Project: $($projectInfo.HasRequirementsTxt)" -ForegroundColor Gray
            Write-Host "  .NET Project: $($projectInfo.HasWebConfig)" -ForegroundColor Gray
            Write-Host "  Docker Project: $($projectInfo.HasDockerfile)" -ForegroundColor Gray
            
            # Suggest database/storage types based on project analysis
            Write-Host "`nSuggested Database/Storage Types:" -ForegroundColor Cyan
            if ($projectInfo.HasPackageJson) {
                Write-Host "  • MongoDB (NoSQL) for Node.js applications" -ForegroundColor Green
                Write-Host "  • PostgreSQL (SQL) for structured data" -ForegroundColor Green
                Write-Host "  • Azure Blob Storage for file uploads" -ForegroundColor Green
            }
            if ($projectInfo.HasRequirementsTxt) {
                Write-Host "  • PostgreSQL (SQL) for Python applications" -ForegroundColor Green
                Write-Host "  • Redis for caching" -ForegroundColor Green
                Write-Host "  • Azure Blob Storage for file storage" -ForegroundColor Green
            }
            if ($projectInfo.HasWebConfig) {
                Write-Host "  • Azure SQL Database for .NET applications" -ForegroundColor Green
                Write-Host "  • Azure Cosmos DB for global applications" -ForegroundColor Green
                Write-Host "  • Azure Blob Storage for file storage" -ForegroundColor Green
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureSQLDatabase" {
            Clear-Host
            Write-Host "=== Deploy Azure SQL Database ===" -ForegroundColor Cyan
            Write-Host "Deploys a SQL Database to Azure" -ForegroundColor Gray
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DatabaseDeploymentParameters -DeploymentType "azuresql" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy Azure SQL Database with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying Azure SQL Database..." -Activity "Step 2/4"
            Write-Host "`nDeploying Azure SQL Database..." -ForegroundColor Yellow
            
            try {
                Deploy-AzureSQLDatabase @params
                Update-ProgressBar -PercentComplete 75 -Status "Database deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAzure SQL Database deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4"
                Write-Host "`nError deploying Azure SQL Database: $_" -ForegroundColor Red
            }
            
            # Step 3: Configure connection strings
            Update-ProgressBar -PercentComplete 90 -Status "Configuring connection strings..." -Activity "Step 4/4"
            Write-Host "`nConfiguring connection strings..." -ForegroundColor Yellow
            
            try {
                Configure-SQLDatabaseConnections @params
                Write-Host "Connection strings configured successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "Warning: Could not configure connection strings: $_" -ForegroundColor Yellow
            }
            
            Update-ProgressBar -PercentComplete 100 -Status "Deployment completed!" -Activity "Step 4/4"
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureCosmosDB" {
            Clear-Host
            Write-Host "=== Deploy Azure Cosmos DB ===" -ForegroundColor Cyan
            Write-Host "Deploys a Cosmos DB instance to Azure" -ForegroundColor Gray
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DatabaseDeploymentParameters -DeploymentType "azurecosmos" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy Azure Cosmos DB with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying Azure Cosmos DB..." -Activity "Step 2/4"
            Write-Host "`nDeploying Azure Cosmos DB..." -ForegroundColor Yellow
            
            try {
                Deploy-AzureCosmosDB @params
                Update-ProgressBar -PercentComplete 75 -Status "Cosmos DB deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAzure Cosmos DB deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4"
                Write-Host "`nError deploying Azure Cosmos DB: $_" -ForegroundColor Red
            }
            
            # Step 3: Configure connection strings
            Update-ProgressBar -PercentComplete 90 -Status "Configuring connection strings..." -Activity "Step 4/4"
            Write-Host "`nConfiguring connection strings..." -ForegroundColor Yellow
            
            try {
                Configure-CosmosDBConnections @params
                Write-Host "Connection strings configured successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "Warning: Could not configure connection strings: $_" -ForegroundColor Yellow
            }
            
            Update-ProgressBar -PercentComplete 100 -Status "Deployment completed!" -Activity "Step 4/4"
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureBlobStorage" {
            Clear-Host
            Write-Host "=== Deploy Azure Blob Storage ===" -ForegroundColor Cyan
            Write-Host "Deploys Azure Blob Storage for file storage" -ForegroundColor Gray
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-StorageDeploymentParameters -DeploymentType "azureblob" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy Azure Blob Storage with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying Azure Blob Storage..." -Activity "Step 2/4"
            Write-Host "`nDeploying Azure Blob Storage..." -ForegroundColor Yellow
            
            try {
                Deploy-AzureBlobStorage @params
                Update-ProgressBar -PercentComplete 75 -Status "Blob Storage deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAzure Blob Storage deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4"
                Write-Host "`nError deploying Azure Blob Storage: $_" -ForegroundColor Red
            }
            
            # Step 3: Configure storage connection
            Update-ProgressBar -PercentComplete 90 -Status "Configuring storage connection..." -Activity "Step 4/4"
            Write-Host "`nConfiguring storage connection..." -ForegroundColor Yellow
            
            try {
                Configure-BlobStorageConnection @params
                Write-Host "Storage connection configured successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "Warning: Could not configure storage connection: $_" -ForegroundColor Yellow
            }
            
            Update-ProgressBar -PercentComplete 100 -Status "Deployment completed!" -Activity "Step 4/4"
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AzureCDN" {
            Clear-Host
            Write-Host "=== Deploy Azure CDN ===" -ForegroundColor Cyan
            Write-Host "Deploys Azure CDN for content delivery" -ForegroundColor Gray
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-StorageDeploymentParameters -DeploymentType "azurecdn" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy Azure CDN with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying Azure CDN..." -Activity "Step 2/4"
            Write-Host "`nDeploying Azure CDN..." -ForegroundColor Yellow
            
            try {
                Deploy-AzureCDN @params
                Update-ProgressBar -PercentComplete 75 -Status "CDN deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAzure CDN deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4"
                Write-Host "`nError deploying Azure CDN: $_" -ForegroundColor Red
            }
            
            # Step 3: Configure CDN endpoints
            Update-ProgressBar -PercentComplete 90 -Status "Configuring CDN endpoints..." -Activity "Step 4/4"
            Write-Host "`nConfiguring CDN endpoints..." -ForegroundColor Yellow
            
            try {
                Configure-CDNEndpoints @params
                Write-Host "CDN endpoints configured successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "Warning: Could not configure CDN endpoints: $_" -ForegroundColor Yellow
            }
            
            Update-ProgressBar -PercentComplete 100 -Status "Deployment completed!" -Activity "Step 4/4"
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AWSRDS" {
            Clear-Host
            Write-Host "=== Deploy AWS RDS ===" -ForegroundColor Cyan
            Write-Host "Deploys an RDS database to AWS" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 AWS RDS deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AWSDynamoDB" {
            Clear-Host
            Write-Host "=== Deploy AWS DynamoDB ===" -ForegroundColor Cyan
            Write-Host "Deploys DynamoDB to AWS" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 AWS DynamoDB deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AWSS3Storage" {
            Clear-Host
            Write-Host "=== Deploy AWS S3 Storage ===" -ForegroundColor Cyan
            Write-Host "Deploys S3 storage to AWS" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 AWS S3 Storage deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-GCPCloudSQL" {
            Clear-Host
            Write-Host "=== Deploy Google Cloud SQL ===" -ForegroundColor Cyan
            Write-Host "Deploys Cloud SQL to Google Cloud" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Google Cloud SQL deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-GCPCloudStorage" {
            Clear-Host
            Write-Host "=== Deploy Google Cloud Storage ===" -ForegroundColor Cyan
            Write-Host "Deploys Cloud Storage to Google Cloud" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Google Cloud Storage deployment coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AutoDetectDatabaseStorage" {
            Clear-Host
            Write-Host "=== Auto-Detect and Deploy Database/Storage ===" -ForegroundColor Cyan
            Write-Host "Automatically detects and deploys appropriate database/storage services" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Auto-detection for database/storage coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Configure-DatabaseConnections" {
            Clear-Host
            Write-Host "=== Configure Database Connections ===" -ForegroundColor Cyan
            Write-Host "Configures connection strings and database settings" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Database connection configuration coming soon!" -ForegroundColor Yellow
            Write-Host "This feature will be implemented in the next update." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Show-DatabaseStorageTypeInfo" {
            Clear-Host
            Write-Host "=== Database & Storage Type Information ===" -ForegroundColor Cyan
            Write-Host ""
            
            Write-Host "📊 Database Types:" -ForegroundColor White
            Write-Host "  • Azure SQL Database: Managed SQL Server database" -ForegroundColor Gray
            Write-Host "  • Azure Cosmos DB: Globally distributed NoSQL database" -ForegroundColor Gray
            Write-Host "  • AWS RDS: Managed relational database service" -ForegroundColor Gray
            Write-Host "  • AWS DynamoDB: Managed NoSQL database service" -ForegroundColor Gray
            Write-Host "  • Google Cloud SQL: Managed MySQL and PostgreSQL" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "💾 Storage Types:" -ForegroundColor White
            Write-Host "  • Azure Blob Storage: Object storage for unstructured data" -ForegroundColor Gray
            Write-Host "  • Azure CDN: Content delivery network" -ForegroundColor Gray
            Write-Host "  • AWS S3: Object storage service" -ForegroundColor Gray
            Write-Host "  • Google Cloud Storage: Object storage service" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🔗 Use Cases:" -ForegroundColor White
            Write-Host "  • SQL Database: Traditional applications, structured data" -ForegroundColor Gray
            Write-Host "  • Cosmos DB: Global applications, microservices" -ForegroundColor Gray
            Write-Host "  • Blob Storage: File uploads, media storage, backups" -ForegroundColor Gray
            Write-Host "  • CDN: Static content delivery, performance optimization" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "List-DeployedDatabasesStorage" {
            Clear-Host
            Write-Host "=== List Deployed Databases & Storage ===" -ForegroundColor Cyan
            Write-Host "Shows all deployed database and storage resources" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "🚧 Database/Storage listing coming soon!" -ForegroundColor Yellow
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