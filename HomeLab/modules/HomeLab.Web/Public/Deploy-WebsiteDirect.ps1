function Deploy-WebsiteDirect {
    <#
    .SYNOPSIS
        Direct website deployment function that doesn't depend on complex module loading.
    
    .DESCRIPTION
        This function provides a self-contained website deployment capability that integrates
        directly with Azure PowerShell without requiring complex module dependencies.
    
    .PARAMETER DeploymentType
        Type of deployment (static|appservice|auto). Default is static.
    
    .PARAMETER ResourceGroup
        Azure Resource Group name.
    
    .PARAMETER AppName
        Application name.
    
    .PARAMETER SubscriptionId
        Azure subscription ID.
    
    .PARAMETER Location
        Azure region. Default is westeurope.
    
    .PARAMETER CustomDomain
        Custom domain (e.g., yourdomain.com).
    
    .PARAMETER Subdomain
        Subdomain for the application (e.g., myapp for myapp.yourdomain.com).
    
    .PARAMETER GitHubToken
        GitHub personal access token (SecureString).
    
    .PARAMETER RepoUrl
        GitHub repository URL.
    
    .PARAMETER Branch
        Git branch to deploy. Default is main.
    
    .PARAMETER ProjectPath
        Path to the project directory for auto-detection.
    
    .EXAMPLE
        Deploy-WebsiteDirect -DeploymentType static -ResourceGroup "rg-myapp" -AppName "myapp" -SubscriptionId "abc123"
    
    .EXAMPLE
        Deploy-WebsiteDirect -DeploymentType auto -ResourceGroup "rg-myapp" -AppName "myapp" -SubscriptionId "abc123" -RepoUrl "https://github.com/user/repo.git"
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet("static", "appservice", "auto")]
        [string]$DeploymentType = "static",
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        
        [Parameter()]
        [string]$Location = "westeurope",
        
        [Parameter()]
        [string]$CustomDomain,
        
        [Parameter()]
        [string]$Subdomain,
        
        [Parameter()]
        [SecureString]$GitHubToken,
        
        [Parameter()]
        [string]$RepoUrl,
        
        [Parameter()]
        [string]$Branch = "main",
        
        [Parameter()]
        [string]$ProjectPath
    )
    
    # Import required functions
    Write-Log -Message "Starting direct website deployment for $AppName" -Level "Info"
    
    try {
        # Ensure Azure context
        if (-not (Test-AzureConnection)) {
            throw "Azure connection not established. Please run Connect-AzAccount first."
        }
        
        # Set subscription context
        Write-Log -Message "Setting subscription context: $SubscriptionId" -Level "Info"
        Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null
        
        # Ensure resource group exists
        $rg = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
        if (-not $rg) {
            Write-Log -Message "Creating resource group: $ResourceGroup" -Level "Info"
            New-AzResourceGroup -Name $ResourceGroup -Location $Location -ErrorAction Stop | Out-Null
            Write-Log -Message "Resource group created successfully" -Level "Success"
        }
        
        # Handle auto-detection
        if ($DeploymentType -eq "auto") {
            $DeploymentType = Get-OptimalDeploymentType -ProjectPath $ProjectPath -RepoUrl $RepoUrl
            Write-Log -Message "Auto-detected deployment type: $DeploymentType" -Level "Info"
        }
        
        # Execute deployment based on type
        switch ($DeploymentType) {
            "static" {
                $result = Deploy-StaticWebAppDirect -AppName $AppName -ResourceGroup $ResourceGroup -Location $Location -RepoUrl $RepoUrl -Branch $Branch -GitHubToken $GitHubToken -CustomDomain $CustomDomain -Subdomain $Subdomain
            }
            "appservice" {
                $result = Deploy-AppServiceDirect -AppName $AppName -ResourceGroup $ResourceGroup -Location $Location -RepoUrl $RepoUrl -Branch $Branch -GitHubToken $GitHubToken -CustomDomain $CustomDomain -Subdomain $Subdomain
            }
            default {
                throw "Invalid deployment type: $DeploymentType"
            }
        }
        
        Write-Log -Message "Deployment completed successfully" -Level "Success"
        return $result
    }
    catch {
        Write-Log -Message "Deployment failed: $($_.Exception.Message)" -Level "Error"
        throw
    }
}

function Get-OptimalDeploymentType {
    <#
    .SYNOPSIS
        Determines the optimal deployment type based on project analysis.
    #>
    param(
        [string]$ProjectPath,
        [string]$RepoUrl
    )
    
    if ($ProjectPath -and (Test-Path $ProjectPath)) {
        return Invoke-ProjectAnalysis -ProjectPath $ProjectPath
    }
    elseif ($RepoUrl) {
        # For GitHub repos without local analysis, default to static
        # In production, you might want to clone and analyze
        Write-Log -Message "GitHub repository specified without local analysis - defaulting to static" -Level "Warning"
        return "static"
    }
    else {
        # Default fallback
        return "static"
    }
}

function Invoke-ProjectAnalysis {
    <#
    .SYNOPSIS
        Analyzes a project directory to determine the optimal deployment type.
    #>
    param([string]$ProjectPath)
    
    Write-Log -Message "Analyzing project at: $ProjectPath" -Level "Info"
    
    # Check for backend indicators
    $indicators = @{
        HasPackageJson = Test-Path "$ProjectPath\package.json"
        HasRequirementsTxt = Test-Path "$ProjectPath\requirements.txt"
        HasCsproj = (Get-ChildItem -Path $ProjectPath -Filter "*.csproj" -Recurse).Count -gt 0
        HasIndexHtml = Test-Path "$ProjectPath\index.html"
        HasBuildFolder = Test-Path "$ProjectPath\build"
        HasDistFolder = Test-Path "$ProjectPath\dist"
    }
    
    # Analyze package.json for server frameworks
    if ($indicators.HasPackageJson) {
        try {
            $packageJson = Get-Content "$ProjectPath\package.json" -Raw | ConvertFrom-Json
            $serverFrameworks = @("express", "koa", "fastify", "hapi", "nestjs")
            
            foreach ($framework in $serverFrameworks) {
                if ($packageJson.dependencies.$framework -or $packageJson.devDependencies.$framework) {
                    Write-Log -Message "Detected server framework: $framework" -Level "Info"
                    return "appservice"
                }
            }
        }
        catch {
            Write-Log -Message "Warning: Could not parse package.json" -Level "Warning"
        }
    }
    
    # Check for Python web frameworks
    if ($indicators.HasRequirementsTxt) {
        $pythonWebFiles = @("wsgi.py", "asgi.py", "manage.py", "app.py")
        foreach ($file in $pythonWebFiles) {
            if (Test-Path "$ProjectPath\$file") {
                Write-Log -Message "Detected Python web application file: $file" -Level "Info"
                return "appservice"
            }
        }
    }
    
    # Check for .NET applications
    if ($indicators.HasCsproj) {
        Write-Log -Message "Detected .NET project" -Level "Info"
        return "appservice"
    }
    
    # Default to static for frontend projects
    if ($indicators.HasIndexHtml -or $indicators.HasBuildFolder -or $indicators.HasDistFolder) {
        Write-Log -Message "Detected static website indicators" -Level "Info"
        return "static"
    }
    
    # Ultimate fallback
    Write-Log -Message "Unable to determine project type - defaulting to static" -Level "Warning"
    return "static"
}

function Deploy-StaticWebAppDirect {
    param(
        [string]$AppName,
        [string]$ResourceGroup,
        [string]$Location,
        [string]$RepoUrl,
        [string]$Branch,
        [SecureString]$GitHubToken,
        [string]$CustomDomain,
        [string]$Subdomain
    )
    
    Write-Log -Message "Deploying Static Web App: $AppName" -Level "Info"
    
    try {
        # Prepare deployment parameters
        $params = @{
            Name = $AppName
            ResourceGroupName = $ResourceGroup
            Location = $Location
            SkuName = "Free"
            SkuTier = "Free"
        }
        
        # Add GitHub integration if available
        if ($RepoUrl) {
            $params.RepositoryUrl = $RepoUrl
            $params.RepositoryBranch = $Branch
            
            if ($GitHubToken) {
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($GitHubToken)
                try {
                    $params.RepositoryToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                }
                finally {
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
                }
            }
        }
        
        # Create the Static Web App
        $staticWebApp = New-AzStaticWebApp @params
        
        # Configure custom domain if specified
        if ($CustomDomain -and $Subdomain) {
            $fullDomain = "$Subdomain.$CustomDomain"
            Write-Log -Message "Configuring custom domain: $fullDomain" -Level "Info"
            
            New-AzStaticWebAppCustomDomain -Name $AppName -ResourceGroupName $ResourceGroup -DomainName $fullDomain
            
            Write-Host "Custom domain configured successfully!" -ForegroundColor Green
            Write-Host "Please configure DNS:" -ForegroundColor Cyan
            Write-Host "Type: CNAME, Name: $Subdomain, Value: $($staticWebApp.DefaultHostname)" -ForegroundColor White
        }
        
        Write-Log -Message "Static Web App deployed successfully" -Level "Success"
        Write-Host "Website URL: https://$($staticWebApp.DefaultHostname)" -ForegroundColor Green
        
        return $staticWebApp
    }
    catch {
        Write-Log -Message "Static Web App deployment failed: $($_.Exception.Message)" -Level "Error"
        throw
    }
}

function Deploy-AppServiceDirect {
    param(
        [string]$AppName,
        [string]$ResourceGroup,
        [string]$Location,
        [string]$RepoUrl,
        [string]$Branch,
        [SecureString]$GitHubToken,
        [string]$CustomDomain,
        [string]$Subdomain
    )
    
    Write-Log -Message "Deploying App Service: $AppName" -Level "Info"
    
    try {
        # Create App Service Plan
        $planName = "$AppName-plan"
        Write-Log -Message "Creating App Service Plan: $planName" -Level "Info"
        
        $appServicePlan = New-AzAppServicePlan -Name $planName -ResourceGroupName $ResourceGroup -Location $Location -Tier Basic -WorkerSize Small -Linux
        
        # Create Web App
        $webApp = New-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroup -Location $Location -AppServicePlan $planName -RuntimeStack "NODE|18-lts"
        
        # Configure GitHub deployment if available
        if ($RepoUrl) {
            Write-Log -Message "Configuring GitHub deployment" -Level "Info"
            
            $sourceControlProps = @{
                repoUrl = $RepoUrl
                branch = $Branch
                isManualIntegration = $true
            }
            
            Set-AzResource -ResourceId "$($webApp.Id)/sourcecontrols/web" -Properties $sourceControlProps -ApiVersion 2015-08-01 -Force
        }
        
        # Configure custom domain if specified
        if ($CustomDomain -and $Subdomain) {
            $fullDomain = "$Subdomain.$CustomDomain"
            Write-Log -Message "Configuring custom domain: $fullDomain" -Level "Info"
            
            Set-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroup -HostNames @($fullDomain, "$AppName.azurewebsites.net")
            
            Write-Host "Custom domain configured successfully!" -ForegroundColor Green
            Write-Host "Please configure DNS:" -ForegroundColor Cyan
            Write-Host "Type: CNAME, Name: $Subdomain, Value: $AppName.azurewebsites.net" -ForegroundColor White
        }
        
        Write-Log -Message "App Service deployed successfully" -Level "Success"
        Write-Host "Website URL: https://$AppName.azurewebsites.net" -ForegroundColor Green
        
        return $webApp
    }
    catch {
        Write-Log -Message "App Service deployment failed: $($_.Exception.Message)" -Level "Error"
        throw
    }
}