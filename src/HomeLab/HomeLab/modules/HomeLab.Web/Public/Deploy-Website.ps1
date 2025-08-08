function Select-ProjectFolder {
    <#
    .SYNOPSIS
        Opens a folder browser dialog to select a project folder.
    
    .DESCRIPTION
        This function displays a folder browser dialog to allow the user to select a project folder.
    
    .EXAMPLE
        $folderPath = Select-ProjectFolder
    #>
    [CmdletBinding()]
    param()
    
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Select the project folder to deploy"
        $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer

        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            return $folderBrowser.SelectedPath
        }

        return $null
    }
    catch {
        Write-Warning "Windows Forms is not available on this system. Cannot use graphical folder browser."
        Write-Host "Please specify the project folder path manually using the -ProjectPath parameter." -ForegroundColor Yellow
        Write-Host "Example: Deploy-Website -ProjectPath 'C:\Path\To\Your\Project'" -ForegroundColor Cyan
        throw "System.Windows.Forms assembly could not be loaded. This may occur on Server Core installations or non-Windows systems. Use -ProjectPath parameter instead."
    }
}

function Deploy-Website {
    <#
    .SYNOPSIS
        Deploys a website to Azure using either Static Web Apps or App Service.
    
    .DESCRIPTION
        This function deploys a website to Azure based on the specified parameters.
        It supports both Static Web Apps and App Service deployments.
    
    .PARAMETER DeploymentType
        Type of deployment (static|appservice). Default is static.
    
    .PARAMETER Subdomain
        Subdomain for the application (e.g., myapp for myapp.yourdomain.com).
    
    .PARAMETER ResourceGroup
        Azure Resource Group name.
    
    .PARAMETER Location
        Azure region. Default is westeurope.
    
    .PARAMETER AppName
        Application name.
    
    .PARAMETER SubscriptionId
        Azure subscription ID.
    
    .PARAMETER CustomDomain
        Custom domain (e.g., yourdomain.com).
    
    .PARAMETER GitHubToken
        GitHub personal access token.
    
    .PARAMETER RepoUrl
        GitHub repository URL.
    
    .PARAMETER Branch
        Git branch to deploy. Default is main.
    
    .PARAMETER ProjectPath
        Path to the project directory.
    
    .EXAMPLE
        Deploy-Website -DeploymentType static -ResourceGroup "myResourceGroup" -AppName "myApp" -SubscriptionId "00000000-0000-0000-0000-000000000000"
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet("static", "appservice", "auto", "vercel", "netlify", "aws", "gcp", "containerapps", "functions", "ecs", "lambda", "cloudfunctions", "aks", "eks", "gke")]
        [string]$DeploymentType = "static",
        
        [Parameter()]
        [string]$Subdomain,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter()]
        [string]$Location = "westeurope",
        
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        
        [Parameter()]
        [string]$CustomDomain,
        
        [Parameter()]
        [SecureString]$GitHubToken,
        
        [Parameter()]
        [string]$RepoUrl,
        
        [Parameter()]
        [string]$Branch = "main",
        
        [Parameter()]
        [string]$ProjectPath,
        
        [Parameter()]
        [string]$Platform,
        
        [Parameter()]
        [string]$VercelToken,
        
        [Parameter()]
        [string]$NetlifyToken,
        
        [Parameter()]
        [string]$AwsRegion,
        
        [Parameter()]
        [string]$GcpProject
    )
    
    # Helper function to determine deployment type based on project characteristics
    function Get-DeploymentType {
        param (
            [string]$Path
        )
        
        # Check for backend indicators
        if (Test-Path -Path (Join-Path $Path "package.json")) {
            try {
                Write-Verbose "Reading package.json from: $(Join-Path $Path "package.json")"
                $packageJsonContent = Get-Content -Path (Join-Path $Path "package.json") -Raw -ErrorAction Stop
                $packageJson = ConvertFrom-Json $packageJsonContent -ErrorAction Stop

                if ($packageJson.dependencies -and
                    ($packageJson.dependencies.express -or
                    $packageJson.dependencies.koa -or
                    $packageJson.dependencies.fastify -or
                    $packageJson.dependencies.hapi)) {
                    Write-Verbose "Detected backend Node.js framework, using appservice deployment"
                    return "appservice"
                }
            }
            catch [System.ArgumentException] {
                Write-Warning "Failed to parse package.json: Invalid JSON format. $($_.Exception.Message)"
                Write-Host "Continuing with static deployment as fallback..." -ForegroundColor Yellow
            }
            catch [System.IO.IOException] {
                Write-Warning "Failed to read package.json: File access error. $($_.Exception.Message)"
                Write-Host "Continuing with static deployment as fallback..." -ForegroundColor Yellow
            }
            catch {
                Write-Warning "Failed to process package.json: $($_.Exception.Message)"
                Write-Host "Continuing with static deployment as fallback..." -ForegroundColor Yellow
            }
        }
        
        if ((Test-Path -Path (Join-Path $Path "requirements.txt")) -or 
            (Test-Path -Path (Join-Path $Path "Pipfile")) -or 
            (Test-Path -Path (Join-Path $Path "setup.py"))) {
            if ((Test-Path -Path (Join-Path $Path "wsgi.py")) -or 
                (Test-Path -Path (Join-Path $Path "asgi.py")) -or 
                (Test-Path -Path (Join-Path $Path "manage.py"))) {
                return "appservice"
            }
        }
        
        if ((Get-ChildItem -Path $Path -Filter "*.csproj" -Recurse) -or 
            (Test-Path -Path (Join-Path $Path "Program.cs")) -or 
            (Test-Path -Path (Join-Path $Path "Startup.cs"))) {
            return "appservice"
        }
        
        # Check for static site indicators
        if ((Test-Path -Path (Join-Path $Path "index.html")) -or 
            (Test-Path -Path (Join-Path $Path "build\index.html")) -or 
            (Test-Path -Path (Join-Path $Path "dist\index.html"))) {
            return "static"
        }
        
        # Default to static if no clear indicators
        return "static"
    }
    
    # Helper function to safely load deployment scripts
    function Import-DeploymentScript {
        param (
            [string]$ScriptPath,
            [string]$ScriptName
        )
        
        try {
            if (Test-Path -Path $ScriptPath) {
                . $ScriptPath
                Write-Verbose "Successfully loaded $ScriptName from: $ScriptPath"
                return $true
            }
            else {
                Write-Error "Deployment script not found: $ScriptPath"
                Write-Host "Please ensure $ScriptName is available in the same directory." -ForegroundColor Yellow
                return $false
            }
        }
        catch {
            Write-Error "Failed to load ${ScriptName}: $($_.Exception.Message)"
            Write-Host "Please check the script file for syntax errors or missing dependencies." -ForegroundColor Yellow
            return $false
        }
    }
    
    # Main execution
    Write-Host "Starting website deployment..."
    Write-Host "Deployment type: $DeploymentType"
    Write-Host "Application name: $AppName"
    Write-Host "Platform: $Platform"
    Write-Host "Location: $Location"
    
    # Auto-detect deployment type if specified (moved before platform-specific checks)
    if ($DeploymentType -eq "auto" -and $ProjectPath) {
        Write-Host "Auto-detecting deployment type..." -ForegroundColor Cyan
        $DeploymentType = Get-DeploymentType -Path $ProjectPath
        Write-Host "Auto-detected deployment type: $DeploymentType" -ForegroundColor Green
    }
    elseif ($DeploymentType -eq "auto" -and -not $ProjectPath) {
        Write-Warning "Auto-detection requires ProjectPath. Defaulting to static deployment."
        $DeploymentType = "static"
    }
    
    # Handle Azure-specific deployments (after auto-detection)
    if ($DeploymentType -in @("static", "appservice") -or $Platform -eq "azure") {
        Write-Host "Using Azure deployment..." -ForegroundColor Cyan
        # Azure-specific logic is now handled in Deploy-Azure function
    }
    
    # Deploy based on type and platform
    switch ($DeploymentType) {
        "static" {
            # Import Azure deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-Azure.ps1" -ScriptName "Deploy-Azure.ps1") {
                $result = Deploy-Azure -AppName $AppName -ResourceGroup $ResourceGroup -Location $Location -SubscriptionId $SubscriptionId -DeploymentType "static" -CustomDomain $CustomDomain -Subdomain $Subdomain -GitHubToken $GitHubToken -RepoUrl $RepoUrl -Branch $Branch -ProjectPath $ProjectPath
            }
            else {
                throw "Failed to load Azure deployment script"
            }
        }
        "appservice" {
            # Import Azure deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-Azure.ps1" -ScriptName "Deploy-Azure.ps1") {
                $result = Deploy-Azure -AppName $AppName -ResourceGroup $ResourceGroup -Location $Location -SubscriptionId $SubscriptionId -DeploymentType "appservice" -CustomDomain $CustomDomain -Subdomain $Subdomain -GitHubToken $GitHubToken -RepoUrl $RepoUrl -Branch $Branch -ProjectPath $ProjectPath
            }
            else {
                throw "Failed to load Azure deployment script"
            }
        }
        "vercel" {
            # Import Vercel deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-Vercel.ps1" -ScriptName "Deploy-Vercel.ps1") {
                $result = Deploy-Vercel -AppName $AppName -ProjectPath $ProjectPath -Location $Location -VercelToken $VercelToken -CustomDomain $CustomDomain -RepoUrl $RepoUrl -Branch $Branch
            }
            else {
                throw "Failed to load Vercel deployment script"
            }
        }
        "netlify" {
            # Import Netlify deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-Netlify.ps1" -ScriptName "Deploy-Netlify.ps1") {
                $result = Deploy-Netlify -AppName $AppName -ProjectPath $ProjectPath -Location $Location -NetlifyToken $NetlifyToken -CustomDomain $CustomDomain -RepoUrl $RepoUrl -Branch $Branch
            }
            else {
                throw "Failed to load Netlify deployment script"
            }
        }
        "aws" {
            # Import AWS deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-AWS.ps1" -ScriptName "Deploy-AWS.ps1") {
                $result = Deploy-AWS -AppName $AppName -ProjectPath $ProjectPath -Location $Location -AwsRegion $AwsRegion -CustomDomain $CustomDomain -RepoUrl $RepoUrl -Branch $Branch
            }
            else {
                throw "Failed to load AWS deployment script"
            }
        }
        "gcp" {
            # Import Google Cloud deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-GoogleCloud.ps1" -ScriptName "Deploy-GoogleCloud.ps1") {
                $result = Deploy-GoogleCloud -AppName $AppName -ProjectPath $ProjectPath -Location $Location -GcpProject $GcpProject -CustomDomain $CustomDomain -RepoUrl $RepoUrl -Branch $Branch
            }
            else {
                throw "Failed to load Google Cloud deployment script"
            }
        }
        "containerapps" {
            # Import Azure Container Apps deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-ContainerApps.ps1" -ScriptName "Deploy-ContainerApps.ps1") {
                $result = Deploy-ContainerApps -AppName $AppName -ResourceGroup $ResourceGroup -SubscriptionId $SubscriptionId -Location $Location -ProjectPath $ProjectPath -CustomDomain $CustomDomain -GitHubToken $GitHubToken -RepoUrl $RepoUrl -Branch $Branch
            }
            else {
                throw "Failed to load Azure Container Apps deployment script"
            }
        }
        "functions" {
            # Import Azure Functions deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-AzureFunctions.ps1" -ScriptName "Deploy-AzureFunctions.ps1") {
                $result = Deploy-AzureFunctions -AppName $AppName -ResourceGroup $ResourceGroup -SubscriptionId $SubscriptionId -Location $Location -ProjectPath $ProjectPath -CustomDomain $CustomDomain -GitHubToken $GitHubToken -RepoUrl $RepoUrl -Branch $Branch
            }
            else {
                throw "Failed to load Azure Functions deployment script"
            }
        }
        "ecs" {
            # Import AWS ECS deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-AWSECS.ps1" -ScriptName "Deploy-AWSECS.ps1") {
                $result = Deploy-AWSECS -AppName $AppName -ProjectPath $ProjectPath -AwsRegion $AwsRegion -CustomDomain $CustomDomain -RepoUrl $RepoUrl -Branch $Branch
            }
            else {
                throw "Failed to load AWS ECS deployment script"
            }
        }
        "lambda" {
            # Import AWS Lambda deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-AWSLambda.ps1" -ScriptName "Deploy-AWSLambda.ps1") {
                $result = Deploy-AWSLambda -AppName $AppName -ProjectPath $ProjectPath -AwsRegion $AwsRegion -CustomDomain $CustomDomain -RepoUrl $RepoUrl -Branch $Branch
            }
            else {
                throw "Failed to load AWS Lambda deployment script"
            }
        }
        "cloudfunctions" {
            # Import Google Cloud Functions deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-GoogleCloudFunctions.ps1" -ScriptName "Deploy-GoogleCloudFunctions.ps1") {
                $result = Deploy-GoogleCloudFunctions -AppName $AppName -ProjectPath $ProjectPath -Location $Location -GcpProject $GcpProject -CustomDomain $CustomDomain -RepoUrl $RepoUrl -Branch $Branch
            }
            else {
                throw "Failed to load Google Cloud Functions deployment script"
            }
        }
        "aks" {
            # Import Azure Kubernetes Service deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-AKS.ps1" -ScriptName "Deploy-AKS.ps1") {
                $result = Deploy-AKS -AppName $AppName -ResourceGroup $ResourceGroup -SubscriptionId $SubscriptionId -Location $Location -ProjectPath $ProjectPath -CustomDomain $CustomDomain -GitHubToken $GitHubToken -RepoUrl $RepoUrl -Branch $Branch
            }
            else {
                throw "Failed to load Azure Kubernetes Service deployment script"
            }
        }
        "eks" {
            # Import AWS EKS deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-AWSEKS.ps1" -ScriptName "Deploy-AWSEKS.ps1") {
                $result = Deploy-AWSEKS -AppName $AppName -ProjectPath $ProjectPath -AwsRegion $AwsRegion -CustomDomain $CustomDomain -RepoUrl $RepoUrl -Branch $Branch
            }
            else {
                throw "Failed to load AWS EKS deployment script"
            }
        }
        "gke" {
            # Import Google Kubernetes Engine deployment function safely
            if (Import-DeploymentScript -ScriptPath "$PSScriptRoot\Deploy-GKE.ps1" -ScriptName "Deploy-GKE.ps1") {
                $result = Deploy-GKE -AppName $AppName -ProjectPath $ProjectPath -Location $Location -GcpProject $GcpProject -CustomDomain $CustomDomain -RepoUrl $RepoUrl -Branch $Branch
            }
            else {
                throw "Failed to load Google Kubernetes Engine deployment script"
            }
        }
        default {
            Write-Error "Error: Invalid deployment type. Use 'static', 'appservice', 'vercel', 'netlify', 'aws', 'gcp', 'containerapps', 'functions', 'ecs', 'lambda', 'cloudfunctions', 'aks', 'eks', or 'gke'"
            return
        }
    }
    
    # Add GitHub workflow files if project path is provided
    if ($ProjectPath) {
        $addWorkflowsPrompt = Read-Host "Would you like to add GitHub workflow files for automatic deployment? (y/n)"
        if ($addWorkflowsPrompt -eq "y") {
            Write-Host "Adding GitHub workflow files for automatic deployment..." -ForegroundColor Yellow
            $workflowParams = @{
                ProjectPath    = $ProjectPath
                DeploymentType = $DeploymentType
            }
            
            if ($CustomDomain) {
                $workflowParams.CustomDomain = $CustomDomain
            }
            
            Add-GitHubWorkflows @workflowParams
            Write-Host "GitHub workflow files added successfully!" -ForegroundColor Green
            Write-Host "You can now use GitHub Actions to deploy this project automatically." -ForegroundColor Green
        }
    }
    
    Write-Host "Deployment completed successfully!"
    return $result
}