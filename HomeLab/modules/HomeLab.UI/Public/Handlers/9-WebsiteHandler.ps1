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
    } catch {
        Write-Error "Failed to import HomeLab.Core module: $_"
        return
    }
    
    try {
        Import-Module HomeLab.Web -ErrorAction Stop
    } catch {
        Write-Error "Failed to import HomeLab.Web module: $_"
        return
    }
    
    # Get configuration
    try {
        $config = Get-Configuration -ErrorAction Stop
    } catch {
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
                Path = $projectPath
                Files = @(Get-ChildItem -Path $projectPath -File | Select-Object -ExpandProperty Name)
                Folders = @(Get-ChildItem -Path $projectPath -Directory | Select-Object -ExpandProperty Name)
                HasPackageJson = Test-Path -Path "$projectPath\package.json"
                HasIndexHtml = Test-Path -Path "$projectPath\index.html"
                HasRequirementsTxt = Test-Path -Path "$projectPath\requirements.txt"
                HasCsproj = (Get-ChildItem -Path $projectPath -Filter "*.csproj" | Measure-Object).Count -gt 0
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
            
            # Import the helper function
            . "$PSScriptRoot\..\..\..\Private\Get-DeploymentParameters.ps1"
            
            # Get deployment parameters using the helper function
            $params = Get-DeploymentParameters -DeploymentType "static" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Deploy website
            Deploy-Website @params
            
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AppServiceWebsite" {
            Clear-Host
            Write-Host "=== Deploy App Service Website ===" -ForegroundColor Cyan
            
            # Import the helper function
            . "$PSScriptRoot\..\..\..\Private\Get-DeploymentParameters.ps1"
            
            # Get deployment parameters using the helper function
            $params = Get-DeploymentParameters -DeploymentType "appservice" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Deploy website
            Deploy-Website @params
            
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Deploy-AutoDetectWebsite" {
            Clear-Host
            Write-Host "=== Auto-Detect and Deploy Website ===" -ForegroundColor Cyan
            
            # Import the helper function
            . "$PSScriptRoot\..\..\..\Private\Get-DeploymentParameters.ps1"
            
            # Get deployment parameters using the helper function
            $params = Get-DeploymentParameters -DeploymentType "auto" -Config $config
            
            if ($null -eq $params) {
                Write-Host "Deployment canceled." -ForegroundColor Red
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return
            }
            
            # Deploy website
            Deploy-Website @params
            
            Write-Host "Press any key to continue..."
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
                ProjectPath = $projectPath
                DeploymentType = $deploymentType
                CustomDomain = $customDomain
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
            } catch {
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
            } catch {
                Write-Host "Failed to retrieve App Services: $_" -ForegroundColor Red
            }
            
            Write-Host "Press any key to continue..."
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
    
    # Show the menu again
    Show-WebsiteMenu
}