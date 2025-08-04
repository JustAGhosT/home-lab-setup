function Invoke-WebsiteHandler {
    <#
    .SYNOPSIS
        Handles website deployment menu commands.
    
    .DESCRIPTION
        This function processes commands from the website deployment menu.
    
    .PARAMETER Command
        The command to process.
    
    .EXAMPLE
        Invoke-WebsiteHandler -Command "Deploy-StaticWebsite"
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
        Import-Module HomeLab.Web -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to import HomeLab.Web module: $_"
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
    function Get-ProjectPathForDeployment {
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
        
        Write-Host "`nSelect the project folder to deploy..." -ForegroundColor Yellow
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
            Write-Host "=== Browse and Select Project ===" -ForegroundColor Cyan
            
            Write-Host "`nSelect a project folder..." -ForegroundColor Yellow
            $projectPath = Select-ProjectFolder
            
            if (-not $projectPath) {
                Write-Host "No folder selected." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            Write-Host "`nSelected project folder: $projectPath" -ForegroundColor Green
            
            # Analyze project structure
            Write-Host "`nAnalyzing project structure..." -ForegroundColor Yellow
            
            $projectInfo = @{
                Path               = $projectPath
                Files              = @(Get-ChildItem -Path $projectPath -File | Select-Object -ExpandProperty Name)
                Folders            = @(Get-ChildItem -Path $projectPath -Directory | Select-Object -ExpandProperty Name)
                HasPackageJson     = Test-Path -Path "$projectPath\package.json"
                HasIndexHtml       = Test-Path -Path "$projectPath\index.html"
                HasRequirementsTxt = Test-Path -Path "$projectPath\requirements.txt"
                HasCsproj          = (Get-ChildItem -Path $projectPath -Filter "*.csproj" | Measure-Object).Count -gt 0
            }
            
            # Display project information
            Write-Host "`nProject Information:" -ForegroundColor Cyan
            Write-Host "  Path: $($projectInfo.Path)"
            Write-Host "  Files: $($projectInfo.Files.Count)"
            Write-Host "  Folders: $($projectInfo.Folders.Count)"
            
            Write-Host "`nDetected Technologies:" -ForegroundColor Cyan
            if ($projectInfo.HasPackageJson) {
                Write-Host "  - Node.js project (package.json found)" -ForegroundColor Green
                
                # Read package.json to get more info
                $packageJson = Get-Content -Path "$projectPath\package.json" -Raw | ConvertFrom-Json
                Write-Host "    Name: $($packageJson.name)"
                Write-Host "    Version: $($packageJson.version)"
                
                # Check for common frameworks
                if ($packageJson.dependencies -ne $null) {
                    if ($packageJson.dependencies.react) {
                        Write-Host "    Framework: React" -ForegroundColor Green
                    }
                    elseif ($packageJson.dependencies.vue) {
                        Write-Host "    Framework: Vue.js" -ForegroundColor Green
                    }
                    elseif ($packageJson.dependencies.angular) {
                        Write-Host "    Framework: Angular" -ForegroundColor Green
                    }
                    elseif ($packageJson.dependencies.express) {
                        Write-Host "    Framework: Express.js (Node.js backend)" -ForegroundColor Green
                    }
                }
            }
            
            if ($projectInfo.HasIndexHtml) {
                Write-Host "  - Static website (index.html found)" -ForegroundColor Green
            }
            
            if ($projectInfo.HasRequirementsTxt) {
                Write-Host "  - Python project (requirements.txt found)" -ForegroundColor Green
            }
            
            if ($projectInfo.HasCsproj) {
                Write-Host "  - .NET project (.csproj found)" -ForegroundColor Green
            }
            
            # Recommend deployment type
            Write-Host "`nRecommended Deployment Type:" -ForegroundColor Cyan
            if ($projectInfo.HasPackageJson -and 
                $packageJson -ne $null -and
                $packageJson.dependencies -ne $null -and
                ($packageJson.dependencies.express -or 
                $packageJson.dependencies.koa -or 
                $packageJson.dependencies.fastify -or 
                $packageJson.dependencies.hapi)) {
                Write-Host "  App Service (Node.js backend detected)" -ForegroundColor Yellow
            }
            elseif ($projectInfo.HasRequirementsTxt -and 
                ((Test-Path -Path "$projectPath\wsgi.py") -or 
                (Test-Path -Path "$projectPath\asgi.py") -or 
                (Test-Path -Path "$projectPath\manage.py"))) {
                Write-Host "  App Service (Python backend detected)" -ForegroundColor Yellow
            }
            elseif ($projectInfo.HasCsproj) {
                Write-Host "  App Service (.NET application detected)" -ForegroundColor Yellow
            }
            elseif ($projectInfo.HasIndexHtml -or 
                (Test-Path -Path "$projectPath\build\index.html") -or 
                (Test-Path -Path "$projectPath\dist\index.html")) {
                Write-Host "  Static Web App (Static website detected)" -ForegroundColor Yellow
            }
            else {
                Write-Host "  Unable to determine optimal deployment type" -ForegroundColor Red
                Write-Host "  Recommend using Auto-Detect deployment option" -ForegroundColor Yellow
            }
            
            # Save project path to script-level variable for use in other commands
            $script:SelectedProjectPath = $projectPath
            
            Write-Host "`nProject path saved. You can now deploy this project using the deployment options." -ForegroundColor Green
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-StaticWebsite" {
            Clear-Host
            Write-Host "=== Deploy Static Website ===" -ForegroundColor Cyan
            Write-Host "Deploys a static website to Azure Static Web Apps" -ForegroundColor Yellow
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "static" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy website with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying static website..." -Activity "Step 2/4"
            Write-Host "`nDeploying static website to Azure..." -ForegroundColor Yellow
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nStatic website deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Resource Group: $($params.ResourceGroup)" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Location: $($params.Location)" -ForegroundColor White
            Write-Host "Deployment Type: Static Website" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AppServiceWebsite" {
            Clear-Host
            Write-Host "=== Deploy App Service Website ===" -ForegroundColor Cyan
            Write-Host "Deploys a web application to Azure App Service" -ForegroundColor Yellow
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "appservice" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy website with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying App Service..." -Activity "Step 2/4"
            Write-Host "`nDeploying web application to Azure App Service..." -ForegroundColor Yellow
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nApp Service deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Resource Group: $($params.ResourceGroup)" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Location: $($params.Location)" -ForegroundColor White
            Write-Host "Deployment Type: App Service" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-VercelWebsite" {
            Clear-Host
            Write-Host "=== Deploy to Vercel ===" -ForegroundColor Cyan
            Write-Host "Deploys a website to Vercel (Next.js, React, Vue optimized)" -ForegroundColor Green
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "vercel" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy to Vercel with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying to Vercel..." -Activity "Step 2/4"
            Write-Host "`nDeploying website to Vercel..." -ForegroundColor Green
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nVercel deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Platform: Vercel" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Location: $($params.Location)" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-NetlifyWebsite" {
            Clear-Host
            Write-Host "=== Deploy to Netlify ===" -ForegroundColor Cyan
            Write-Host "Deploys a static website to Netlify (JAMstack optimized)" -ForegroundColor Blue
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "netlify" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy to Netlify with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying to Netlify..." -Activity "Step 2/4"
            Write-Host "`nDeploying static website to Netlify..." -ForegroundColor Blue
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nNetlify deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Platform: Netlify" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Location: $($params.Location)" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AWSWebsite" {
            Clear-Host
            Write-Host "=== Deploy to AWS ===" -ForegroundColor Cyan
            Write-Host "Deploys a website to AWS (S3 + CloudFront, Amplify)" -ForegroundColor Yellow
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "aws" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy to AWS with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying to AWS..." -Activity "Step 2/4"
            Write-Host "`nDeploying website to AWS..." -ForegroundColor Yellow
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAWS deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Platform: AWS" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Location: $($params.Location)" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-GCPWebsite" {
            Clear-Host
            Write-Host "=== Deploy to Google Cloud ===" -ForegroundColor Cyan
            Write-Host "Deploys a website to Google Cloud (Cloud Run, App Engine)" -ForegroundColor Red
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "gcp" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy to Google Cloud with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying to Google Cloud..." -Activity "Step 2/4"
            Write-Host "`nDeploying website to Google Cloud..." -ForegroundColor Red
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nGoogle Cloud deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Platform: Google Cloud" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Location: $($params.Location)" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AutoDetectWebsite" {
            Clear-Host
            Write-Host "=== Auto-Detect and Deploy Website ===" -ForegroundColor Cyan
            Write-Host "Analyzes your project and chooses the best deployment type" -ForegroundColor Yellow
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 20 -Activity "Step 1/5" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "auto" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Analyze project for auto-detection
            Update-ProgressBar -PercentComplete 40 -Status "Analyzing project structure..." -Activity "Step 2/5"
            Write-Host "`nAnalyzing project structure for optimal deployment type..." -ForegroundColor Yellow
            
            # Step 3: Deploy website with progress
            Update-ProgressBar -PercentComplete 60 -Status "Deploying website..." -Activity "Step 3/5"
            Write-Host "`nDeploying website with auto-detected configuration..." -ForegroundColor Yellow
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 80 -Status "Deployment completed successfully!" -Activity "Step 4/5"
                Write-Host "`nWebsite deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 5/5" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 4: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 5/5"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Resource Group: $($params.ResourceGroup)" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Location: $($params.Location)" -ForegroundColor White
            Write-Host "Deployment Type: Auto-detected" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Configure-WebsiteCustomDomain" {
            Clear-Host
            Write-Host "=== Configure Custom Domain ===" -ForegroundColor Cyan
            
            # Get parameters
            $resourceGroup = Read-Host "Enter resource group name"
            $appName = Read-Host "Enter application name"
            $customDomain = Read-Host "Enter domain name (e.g., example.com)"
            $subdomain = Read-Host "Enter subdomain (e.g., www)"
            $websiteType = Read-Host "Website type (static/appservice)"
            
            # Configure custom domain
            if ($websiteType -eq "static") {
                Configure-CustomDomainStatic -AppName $appName -ResourceGroup $resourceGroup -Domain "$subdomain.$customDomain"
            }
            else {
                Configure-CustomDomainAppService -AppName $appName -ResourceGroup $resourceGroup -Domain "$subdomain.$customDomain"
            }
            
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Add-GitHubWorkflowsMenu" {
            Clear-Host
            Write-Host "=== Add GitHub Workflows ===" -ForegroundColor Cyan
            
            # Get project path
            $projectPath = Get-ProjectPathForDeployment
            if (-not $projectPath) {
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Get deployment type
            Write-Host "`nSelect deployment type:" -ForegroundColor Yellow
            Write-Host "1. Static Website"
            Write-Host "2. App Service"
            Write-Host "3. Auto-detect"
            $deploymentTypeChoice = Read-Host "Enter choice (1-3)"
            
            switch ($deploymentTypeChoice) {
                "1" { $deploymentType = "static" }
                "2" { $deploymentType = "appservice" }
                "3" { $deploymentType = "auto" }
                default {
                    Write-Host "Invalid choice. Using auto-detect." -ForegroundColor Yellow
                    $deploymentType = "auto"
                }
            }
            
            # Get custom domain
            $useCustomDomain = Read-Host "Configure custom domain? (y/n)"
            if ($useCustomDomain -eq "y") {
                $customDomain = Read-Host "Enter domain name (e.g., example.com)"
            }
            else {
                $customDomain = "liquidmesh.ai"
            }
            
            # Add GitHub workflows
            $params = @{
                ProjectPath    = $projectPath
                DeploymentType = $deploymentType
                CustomDomain   = $customDomain
            }
            
            # Ask for GitHub token if needed
            $needsToken = Read-Host "Do you need to provide a GitHub token? (y/n)"
            if ($needsToken -eq "y") {
                # Securely capture GitHub token
                $secureGitHubToken = Read-Host "Enter GitHub personal access token" -AsSecureString
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureGitHubToken)
                $gitHubToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
                
                $params.GitHubToken = $gitHubToken
            }
            
            Add-GitHubWorkflows @params
            
            Write-Host "`nGitHub workflow files added successfully!" -ForegroundColor Green
            Write-Host "You can now use GitHub Actions to deploy this project automatically." -ForegroundColor Green
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Show-DeploymentTypeInfoMenu" {
            Clear-Host
            Write-Host "=== Deployment Type Information ===" -ForegroundColor Cyan
            
            Write-Host "`nSelect deployment type to view information:" -ForegroundColor Yellow
            Write-Host "1. Static Website"
            Write-Host "2. App Service"
            Write-Host "3. Both (comparison)"
            $deploymentTypeChoice = Read-Host "Enter choice (1-3)"
            
            switch ($deploymentTypeChoice) {
                "1" { Show-DeploymentTypeInfo -DeploymentType "static" }
                "2" { Show-DeploymentTypeInfo -DeploymentType "appservice" }
                "3" { Show-DeploymentTypeInfo }
                default { Show-DeploymentTypeInfo }
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "List-DeployedWebsites" {
            Clear-Host
            Write-Host "=== Deployed Websites ===" -ForegroundColor Cyan
            
            # Get resource group
            $resourceGroup = Read-Host "Enter resource group name (leave empty for all)"
            
            # List static web apps
            Write-Host "`nStatic Web Apps:" -ForegroundColor Yellow
            try {
                if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
                    Get-AzStaticWebApp -ErrorAction Stop | Format-Table Name, ResourceGroupName, DefaultHostname
                }
                else {
                    Get-AzStaticWebApp -ResourceGroupName $resourceGroup -ErrorAction Stop | Format-Table Name, ResourceGroupName, DefaultHostname
                }
            }
            catch {
                Write-Host "Failed to retrieve Static Web Apps: $_" -ForegroundColor Red
            }
            
            # List app services
            Write-Host "`nApp Services:" -ForegroundColor Yellow
            try {
                if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
                    Get-AzWebApp -ErrorAction Stop | Format-Table Name, ResourceGroup, DefaultHostName
                }
                else {
                    Get-AzWebApp -ResourceGroupName $resourceGroup -ErrorAction Stop | Format-Table Name, ResourceGroup, DefaultHostName
                }
            }
            catch {
                Write-Host "Failed to retrieve App Services: $_" -ForegroundColor Red
            }
            
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-ContainerAppsWebsite" {
            Clear-Host
            Write-Host "=== Deploy to Azure Container Apps ===" -ForegroundColor Cyan
            Write-Host "Deploys a containerized application to Azure Container Apps (serverless containers)" -ForegroundColor Yellow
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "containerapps" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy to Azure Container Apps with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying to Azure Container Apps..." -Activity "Step 2/4"
            Write-Host "`nDeploying containerized application to Azure Container Apps..." -ForegroundColor Yellow
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAzure Container Apps deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Platform: Azure Container Apps" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Location: $($params.Location)" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-FunctionsWebsite" {
            Clear-Host
            Write-Host "=== Deploy to Azure Functions ===" -ForegroundColor Cyan
            Write-Host "Deploys serverless functions to Azure Functions" -ForegroundColor Yellow
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "functions" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy to Azure Functions with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying to Azure Functions..." -Activity "Step 2/4"
            Write-Host "`nDeploying serverless functions to Azure Functions..." -ForegroundColor Yellow
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAzure Functions deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Platform: Azure Functions" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Location: $($params.Location)" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-ECSWebsite" {
            Clear-Host
            Write-Host "=== Deploy to AWS ECS Fargate ===" -ForegroundColor Cyan
            Write-Host "Deploys a containerized application to AWS ECS with Fargate (serverless containers)" -ForegroundColor Yellow
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "ecs" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy to AWS ECS with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying to AWS ECS Fargate..." -Activity "Step 2/4"
            Write-Host "`nDeploying containerized application to AWS ECS Fargate..." -ForegroundColor Yellow
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAWS ECS Fargate deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Platform: AWS ECS Fargate" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Region: $($params.AwsRegion)" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-LambdaWebsite" {
            Clear-Host
            Write-Host "=== Deploy to AWS Lambda ===" -ForegroundColor Cyan
            Write-Host "Deploys serverless functions to AWS Lambda" -ForegroundColor Yellow
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "lambda" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy to AWS Lambda with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying to AWS Lambda..." -Activity "Step 2/4"
            Write-Host "`nDeploying serverless functions to AWS Lambda..." -ForegroundColor Yellow
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAWS Lambda deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Platform: AWS Lambda" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Region: $($params.AwsRegion)" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-CloudFunctionsWebsite" {
            Clear-Host
            Write-Host "=== Deploy to Google Cloud Functions ===" -ForegroundColor Cyan
            Write-Host "Deploys serverless functions to Google Cloud Functions" -ForegroundColor Yellow
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "cloudfunctions" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy to Google Cloud Functions with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying to Google Cloud Functions..." -Activity "Step 2/4"
            Write-Host "`nDeploying serverless functions to Google Cloud Functions..." -ForegroundColor Yellow
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nGoogle Cloud Functions deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Platform: Google Cloud Functions" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Location: $($params.Location)" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AKSWebsite" {
            Clear-Host
            Write-Host "=== Deploy to Azure Kubernetes Service (AKS) ===" -ForegroundColor Cyan
            Write-Host "Deploys a containerized application to Azure Kubernetes Service" -ForegroundColor Yellow
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "aks" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy to AKS with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying to Azure Kubernetes Service..." -Activity "Step 2/4"
            Write-Host "`nDeploying containerized application to Azure Kubernetes Service..." -ForegroundColor Yellow
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAzure Kubernetes Service deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Platform: Azure Kubernetes Service (AKS)" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Location: $($params.Location)" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-EKSWebsite" {
            Clear-Host
            Write-Host "=== Deploy to AWS EKS (Elastic Kubernetes Service) ===" -ForegroundColor Cyan
            Write-Host "Deploys a containerized application to AWS EKS" -ForegroundColor Yellow
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "eks" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy to EKS with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying to AWS EKS..." -Activity "Step 2/4"
            Write-Host "`nDeploying containerized application to AWS EKS..." -ForegroundColor Yellow
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nAWS EKS deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Platform: AWS EKS (Elastic Kubernetes Service)" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Region: $($params.AwsRegion)" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-GKEWebsite" {
            Clear-Host
            Write-Host "=== Deploy to Google Kubernetes Engine (GKE) ===" -ForegroundColor Cyan
            Write-Host "Deploys a containerized application to Google Kubernetes Engine" -ForegroundColor Yellow
            Write-Host ""
            
            # Import the helper functions
            . "$PSScriptRoot\..\..\Private\Get-DeploymentParameters.ps1"
            . "$PSScriptRoot\..\ProgressBar\Show-ProgressBar.ps1"
            . "$PSScriptRoot\..\ProgressBar\Update-ProgressBar.ps1"
            . "$PSScriptRoot\..\..\Private\Helpers.ps1"
            
            # Step 1: Get deployment parameters with progress
            Show-ProgressBar -PercentComplete 25 -Activity "Step 1/4" -Status "Collecting deployment parameters..." -ForegroundColor Cyan
            $params = Get-DeploymentParameters -DeploymentType "gke" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 2: Deploy to GKE with progress
            Update-ProgressBar -PercentComplete 50 -Status "Deploying to Google Kubernetes Engine..." -Activity "Step 2/4"
            Write-Host "`nDeploying containerized application to Google Kubernetes Engine..." -ForegroundColor Yellow
            
            try {
                Deploy-Website @params
                Update-ProgressBar -PercentComplete 75 -Status "Deployment completed successfully!" -Activity "Step 3/4"
                Write-Host "`nGoogle Kubernetes Engine deployment completed successfully!" -ForegroundColor Green
            }
            catch {
                Update-ProgressBar -PercentComplete 100 -Status "Deployment failed!" -Activity "Step 4/4" -ForegroundColor Red
                Write-Host "`nDeployment failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Step 3: Show final summary
            Update-ProgressBar -PercentComplete 100 -Status "Process complete!" -Activity "Step 4/4"
            Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
            Write-Host "Platform: Google Kubernetes Engine (GKE)" -ForegroundColor White
            Write-Host "Application Name: $($params.AppName)" -ForegroundColor White
            Write-Host "Location: $($params.Location)" -ForegroundColor White
            
            if ($params.CustomDomain) {
                Write-Host "Custom Domain: $($params.Subdomain).$($params.CustomDomain)" -ForegroundColor White
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Back" {
            # Return to main menu
            return
        }
        
        default {
            Write-Host "Unknown command: $Command"
            Start-Sleep -Seconds 2
        }
    }
}