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
        [ValidateSet("static", "appservice", "auto", "vercel", "netlify", "aws", "gcp")]
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
    
    # Azure-specific functions are now in Deploy-Azure.ps1
    

    

    

    
    # Main execution
    Write-Host "Starting website deployment..."
    Write-Host "Deployment type: $DeploymentType"
    Write-Host "Application name: $AppName"
    Write-Host "Platform: $Platform"
    Write-Host "Location: $Location"
    
    # Handle Azure-specific deployments
    if ($DeploymentType -in @("static", "appservice", "auto") -or $Platform -eq "azure") {
        Write-Host "Using Azure deployment..." -ForegroundColor Cyan
        # Azure-specific logic is now handled in Deploy-Azure function
    }
    
    # Auto-detect deployment type if specified
    if ($DeploymentType -eq "auto" -and $ProjectPath) {
        $DeploymentType = Get-DeploymentType -Path $ProjectPath
        Write-Host "Auto-detected deployment type: $DeploymentType"
    }
    
    # Deploy based on type and platform
    switch ($DeploymentType) {
        "static" {
            # Import Azure deployment function
            . "$PSScriptRoot\Deploy-Azure.ps1"
            $result = Deploy-Azure -AppName $AppName -ResourceGroup $ResourceGroup -Location $Location -SubscriptionId $SubscriptionId -DeploymentType "static" -CustomDomain $CustomDomain -Subdomain $Subdomain -GitHubToken $GitHubToken -RepoUrl $RepoUrl -Branch $Branch -ProjectPath $ProjectPath
        }
        "appservice" {
            # Import Azure deployment function
            . "$PSScriptRoot\Deploy-Azure.ps1"
            $result = Deploy-Azure -AppName $AppName -ResourceGroup $ResourceGroup -Location $Location -SubscriptionId $SubscriptionId -DeploymentType "appservice" -CustomDomain $CustomDomain -Subdomain $Subdomain -GitHubToken $GitHubToken -RepoUrl $RepoUrl -Branch $Branch -ProjectPath $ProjectPath
        }
        "vercel" {
            # Import Vercel deployment function
            . "$PSScriptRoot\Deploy-Vercel.ps1"
            $result = Deploy-Vercel -AppName $AppName -ProjectPath $ProjectPath -Location $Location -VercelToken $VercelToken -CustomDomain $CustomDomain -RepoUrl $RepoUrl -Branch $Branch
        }
        "netlify" {
            # Import Netlify deployment function
            . "$PSScriptRoot\Deploy-Netlify.ps1"
            $result = Deploy-Netlify -AppName $AppName -ProjectPath $ProjectPath -Location $Location -NetlifyToken $NetlifyToken -CustomDomain $CustomDomain -RepoUrl $RepoUrl -Branch $Branch
        }
        "aws" {
            # Import AWS deployment function
            . "$PSScriptRoot\Deploy-AWS.ps1"
            $result = Deploy-AWS -AppName $AppName -ProjectPath $ProjectPath -Location $Location -AwsRegion $AwsRegion -CustomDomain $CustomDomain -RepoUrl $RepoUrl -Branch $Branch
        }
        "gcp" {
            # Import Google Cloud deployment function
            . "$PSScriptRoot\Deploy-GoogleCloud.ps1"
            $result = Deploy-GoogleCloud -AppName $AppName -ProjectPath $ProjectPath -Location $Location -GcpProject $GcpProject -CustomDomain $CustomDomain -RepoUrl $RepoUrl -Branch $Branch
        }
        default {
            Write-Error "Error: Invalid deployment type. Use 'static', 'appservice', 'vercel', 'netlify', 'aws', or 'gcp'"
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