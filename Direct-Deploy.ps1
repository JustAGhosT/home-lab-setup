# Direct deployment function embedded in this file
function Deploy-Website-Direct {
    <#
    .SYNOPSIS
        Direct deployment function for Azure websites
    .DESCRIPTION
        Deploys websites directly to Azure using PowerShell modules
    .PARAMETER DeploymentType
        Type of deployment: static, appservice, or auto
    .PARAMETER ResourceGroup
        Azure resource group name
    .PARAMETER Location
        Azure location
    .PARAMETER AppName
        Application name
    .PARAMETER SubscriptionId
        Azure subscription ID
    .PARAMETER CustomDomain
        Custom domain name
    .PARAMETER Subdomain
        Subdomain name
    .PARAMETER RepoUrl
        GitHub repository URL
    .PARAMETER Branch
        Git branch name
    .PARAMETER GitHubToken
        GitHub personal access token as SecureString
    .PARAMETER ProjectPath
        Local project path
    .PARAMETER RecursionDepth
        Internal parameter to prevent infinite recursion
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("static", "appservice", "auto")]
        [string]$DeploymentType,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$Location,
        
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        
        [Parameter()]
        [string]$CustomDomain,
        
        [Parameter()]
        [string]$Subdomain,
        
        [Parameter()]
        [string]$RepoUrl,
        
        [Parameter()]
        [string]$Branch = "main",
        
        [Parameter()]
        [System.Security.SecureString]$GitHubToken,
        
        [Parameter()]
        [string]$ProjectPath,
        
        [Parameter()]
        [int]$RecursionDepth = 0
    )
    
    # Recursion guard to prevent infinite recursion
    if ($RecursionDepth -gt 2) {
        throw "Maximum recursion depth exceeded. Auto-detection failed to determine deployment type."
    }
    
    Write-Host "Direct Deployment Function Ready" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Cyan

    # 1. Login to Azure if not already logged in (using Azure PowerShell only)
    try {
        $context = Get-AzContext -ErrorAction Stop
        if (-not $context) {
            Write-Host "Not logged in to Azure. Please login." -ForegroundColor Yellow
            Connect-AzAccount -ErrorAction Stop
        }
        else {
            Write-Host "Already logged in as $($context.Account.Id)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error checking Azure login status: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please login to Azure." -ForegroundColor Yellow
        Connect-AzAccount -ErrorAction Stop
    }

    # 2. Set the subscription context (using Azure PowerShell only)
    try {
        Write-Host "Setting Azure subscription context to: $SubscriptionId" -ForegroundColor Yellow
        Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
        Write-Host "Subscription context set successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error setting subscription context: $($_.Exception.Message)" -ForegroundColor Red
        throw "Failed to set subscription context."
    }

    # 3. Check if resource group exists and create if necessary (using Azure PowerShell only)
    try {
        $resourceGroupExists = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
        if (-not $resourceGroupExists) {
            Write-Host "Creating resource group: $ResourceGroup in $Location" -ForegroundColor Yellow
            New-AzResourceGroup -Name $ResourceGroup -Location $Location -ErrorAction Stop
            Write-Host "Resource group created successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Resource group already exists: $ResourceGroup" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error managing resource group: $($_.Exception.Message)" -ForegroundColor Red
        throw "Failed to create or validate resource group."
    }

    # 4. Deploy based on type
    try {
        if ($DeploymentType -eq "static") {
            # Deploy Static Web App
            Write-Host "Deploying Azure Static Web App: $AppName" -ForegroundColor Yellow
            
            # Create deployment parameters
            $staticWebAppParams = @{
                Name              = $AppName
                ResourceGroupName = $ResourceGroup
                Location          = $Location
                SkuName           = "Free"
                SkuTier           = "Free"
            }
            
            # Add GitHub info if available
            if ($RepoUrl) {
                $staticWebAppParams.RepositoryUrl = $RepoUrl
                $staticWebAppParams.RepositoryBranch = $Branch
                
                # Convert SecureString to plain text for API call with proper memory cleanup
                if ($GitHubToken) {
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($GitHubToken)
                    try {
                        $plainTextToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                        $staticWebAppParams.RepositoryToken = $plainTextToken
                    }
                    finally {
                        # Clear plain text from memory immediately
                        if ($plainTextToken) {
                            $plainTextToken = $null
                        }
                        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
                        [System.GC]::Collect()
                    }
                }
            }
            
            # Create the static web app
            $staticWebApp = New-AzStaticWebApp @staticWebAppParams -ErrorAction Stop
            
            # Configure custom domain if provided
            if ($CustomDomain -and $Subdomain) {
                $domain = "$Subdomain.$CustomDomain"
                Write-Host "Configuring custom domain: $domain" -ForegroundColor Yellow
                
                New-AzStaticWebAppCustomDomain -Name $AppName -ResourceGroupName $ResourceGroup -DomainName $domain -ErrorAction Stop
                
                Write-Host "Custom domain configured successfully." -ForegroundColor Green
                Write-Host "Please update your DNS records:" -ForegroundColor Cyan
                Write-Host "Type: CNAME" -ForegroundColor White
                Write-Host "Name: $Subdomain" -ForegroundColor White
                Write-Host "Value: $($staticWebApp.DefaultHostname)" -ForegroundColor White
            }
            
            Write-Host "Static Web App deployed successfully!" -ForegroundColor Green
            if ($staticWebApp.DefaultHostname) {
                Write-Host "Your website is available at: https://$($staticWebApp.DefaultHostname)" -ForegroundColor Cyan
            }
            
            return $staticWebApp
        }
        elseif ($DeploymentType -eq "appservice") {
            # Deploy App Service
            Write-Host "Deploying Azure App Service: $AppName" -ForegroundColor Yellow
            
            # Create App Service Plan
            $planName = "$AppName-plan"
            Write-Host "Creating App Service Plan: $planName" -ForegroundColor Yellow
            $appServicePlan = New-AzAppServicePlan -Name $planName -ResourceGroupName $ResourceGroup -Location $Location -Tier Basic -WorkerSize Small -Linux -ErrorAction Stop
            Write-Host "App Service Plan created successfully." -ForegroundColor Green
            
            # Create Web App
            Write-Host "Creating Web App: $AppName" -ForegroundColor Yellow
            $webApp = New-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroup -Location $Location -AppServicePlan $planName -RuntimeStack "NODE|18-lts" -ErrorAction Stop
            Write-Host "Web App created successfully." -ForegroundColor Green
            
            # Configure GitHub deployment if provided
            if ($RepoUrl) {
                Write-Host "Configuring GitHub deployment." -ForegroundColor Yellow
                
                $props = @{
                    repoUrl             = $RepoUrl
                    branch              = $Branch
                    isManualIntegration = $true
                }
                
                Set-AzResource -ResourceId "$($webApp.Id)/sourcecontrols/web" -Properties $props -ApiVersion 2015-08-01 -Force -ErrorAction Stop
                Write-Host "GitHub deployment configured successfully." -ForegroundColor Green
            }
            
            # Configure custom domain if provided
            if ($CustomDomain -and $Subdomain) {
                $domain = "$Subdomain.$CustomDomain"
                Write-Host "Configuring custom domain: $domain" -ForegroundColor Yellow
                
                Set-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroup -HostNames @($domain, "$AppName.azurewebsites.net") -ErrorAction Stop
                
                Write-Host "Custom domain configured successfully." -ForegroundColor Green
                Write-Host "Please update your DNS records:" -ForegroundColor Cyan
                Write-Host "Type: CNAME" -ForegroundColor White
                Write-Host "Name: $Subdomain" -ForegroundColor White
                Write-Host "Value: $AppName.azurewebsites.net" -ForegroundColor White
            }
            
            Write-Host "App Service deployed successfully!" -ForegroundColor Green
            Write-Host "Your website is available at: https://$AppName.azurewebsites.net" -ForegroundColor Cyan
            
            return $webApp
        }
        elseif ($DeploymentType -eq "auto") {
            # Determine deployment type based on project analysis
            if ($ProjectPath) {
                Write-Host "=== Auto-Detection Progress ===" -ForegroundColor Cyan
                Write-Host "Analyzing project at: $ProjectPath" -ForegroundColor Yellow
                
                # Progress tracking for auto-detection
                $analysisSteps = 4
                $currentStep = 0
                
                # Step 1: Check for Node.js frameworks
                $currentStep++
                Write-Host ("`nStep {0}/{1}: Checking for Node.js frameworks..." -f $currentStep, $analysisSteps) -ForegroundColor Cyan
                
                $isServerSide = $false
                if (Test-Path -Path "$ProjectPath\package.json") {
                    $packageJson = Get-Content -Path "$ProjectPath\package.json" | ConvertFrom-Json
                    if ($packageJson.dependencies -or $packageJson.devDependencies) {
                        # Check for server-side frameworks
                        $serverFrameworks = @("express", "koa", "fastify", "hapi", "restify", "adonis", "strapi", "next", "nuxt")
                        $hasServerFramework = $false
                        
                        foreach ($framework in $serverFrameworks) {
                            if ($packageJson.dependencies[$framework] -or $packageJson.devDependencies[$framework]) {
                                $hasServerFramework = $true
                                break
                            }
                        }
                        
                        if ($hasServerFramework) {
                            $isServerSide = $true
                            Write-Host "[OK] Detected Node.js server framework - will use App Service." -ForegroundColor Green
                        }
                        else {
                            Write-Host "[OK] Node.js project detected but no server framework found." -ForegroundColor Gray
                        }
                    }
                }
                else {
                    Write-Host "[OK] No package.json found." -ForegroundColor Gray
                }
                
                # Step 2: Check for Python frameworks
                $currentStep++
                Write-Host ("`nStep {0}/{1}: Checking for Python frameworks..." -f $currentStep, $analysisSteps) -ForegroundColor Cyan
                
                if ((Test-Path -Path "$ProjectPath\requirements.txt") -or
                    (Test-Path -Path "$ProjectPath\Pipfile") -or
                    (Test-Path -Path "$ProjectPath\setup.py")) {
                    if ((Test-Path -Path "$ProjectPath\wsgi.py") -or
                        (Test-Path -Path "$ProjectPath\asgi.py") -or
                        (Test-Path -Path "$ProjectPath\manage.py")) {
                        $isServerSide = $true
                        Write-Host "[OK] Detected Python web framework - will use App Service." -ForegroundColor Green
                    }
                    else {
                        Write-Host "[OK] Python dependencies found but no web framework detected." -ForegroundColor Gray
                    }
                }
                else {
                    Write-Host "[OK] No Python web framework detected." -ForegroundColor Gray
                }
                
                # Step 3: Check for .NET frameworks
                $currentStep++
                Write-Host ("`nStep {0}/{1}: Checking for .NET frameworks..." -f $currentStep, $analysisSteps) -ForegroundColor Cyan
                
                if ((Get-ChildItem -Path $ProjectPath -Filter "*.csproj" -Recurse) -or
                    (Test-Path -Path "$ProjectPath\Program.cs") -or
                    (Test-Path -Path "$ProjectPath\Startup.cs")) {
                    $isServerSide = $true
                    Write-Host "[OK] Detected .NET application - will use App Service." -ForegroundColor Green
                }
                else {
                    Write-Host "[OK] No .NET application detected." -ForegroundColor Gray
                }
                
                # Step 4: Check for static site indicators
                $currentStep++
                Write-Host ("`nStep {0}/{1}: Checking for static site files..." -f $currentStep, $analysisSteps) -ForegroundColor Cyan
                
                $isStaticSite = $false
                if ((Test-Path -Path "$ProjectPath\index.html") -or
                    (Test-Path -Path "$ProjectPath\build\index.html") -or
                    (Test-Path -Path "$ProjectPath\dist\index.html")) {
                    $isStaticSite = $true
                    Write-Host "[OK] Detected static website files - will use Static Web App." -ForegroundColor Green
                }
                else {
                    Write-Host "[OK] No static site files detected." -ForegroundColor Gray
                }
                
                # Determine deployment type
                Write-Host "`n=== Analysis Results ===" -ForegroundColor Cyan
                if ($isServerSide) {
                    $detectedType = "appservice"
                    Write-Host "[OK] Server-side application detected - using App Service deployment." -ForegroundColor Green
                }
                elseif ($isStaticSite) {
                    $detectedType = "static"
                    Write-Host "[OK] Static website detected - using Static Web App deployment." -ForegroundColor Green
                }
                else {
                    # Default to static if unclear
                    $detectedType = "static"
                    Write-Host "[WARN] Could not clearly determine project type - defaulting to Static Web App." -ForegroundColor Yellow
                }
                
                Write-Host "`nAuto-detection complete. Using deployment type: $detectedType" -ForegroundColor Green
                Write-Host "Proceeding with deployment..." -ForegroundColor Cyan
                
                # Call this function recursively with the detected type and increased recursion depth
                return Deploy-Website-Direct -DeploymentType $detectedType -ResourceGroup $ResourceGroup -Location $Location -AppName $AppName -SubscriptionId $SubscriptionId -CustomDomain $CustomDomain -Subdomain $Subdomain -RepoUrl $RepoUrl -Branch $Branch -GitHubToken $GitHubToken -ProjectPath $ProjectPath -RecursionDepth ($RecursionDepth + 1)
            }
            elseif ($RepoUrl) {
                # For GitHub repos, we'll default to static for now
                # In a production environment, you'd want to clone the repo and analyze it
                Write-Host "GitHub repository provided but no local path for analysis - defaulting to Static Web App." -ForegroundColor Yellow
                return Deploy-Website-Direct -DeploymentType "static" -ResourceGroup $ResourceGroup -Location $Location -AppName $AppName -SubscriptionId $SubscriptionId -CustomDomain $CustomDomain -Subdomain $Subdomain -RepoUrl $RepoUrl -Branch $Branch -GitHubToken $GitHubToken -RecursionDepth ($RecursionDepth + 1)
            }
            else {
                throw "Project path or GitHub repository required for auto-detection."
            }
        }
        else {
            throw "Invalid deployment type: $DeploymentType"
        }
    }
    catch {
        Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.InnerException) {
            Write-Host "Details: $($_.Exception.InnerException.Message)" -ForegroundColor Red
        }
        throw "Deployment failed."
    }
}