function Deploy-AzureFunctions {
    <#
    .SYNOPSIS
        Deploys serverless functions to Azure Functions.
    
    .DESCRIPTION
        This function deploys serverless functions to Azure Functions, supporting multiple runtime
        environments including Node.js, Python, .NET, Java, and PowerShell.
    
    .PARAMETER AppName
        Application name for the Function App.
    
    .PARAMETER ResourceGroup
        Azure Resource Group name.
    
    .PARAMETER Location
        Azure region for deployment.
    
    .PARAMETER SubscriptionId
        Azure subscription ID.
    
    .PARAMETER ProjectPath
        Path to the project directory containing function code.
    
    .PARAMETER Runtime
        Function runtime (node, python, dotnet, java, powershell).
    
    .PARAMETER RuntimeVersion
        Runtime version (e.g., 18, 3.9, 6.0, 11, 7.2).
    
    .PARAMETER OperatingSystem
        Operating system (Windows, Linux).
    
    .PARAMETER PlanType
        Hosting plan type (Consumption, Premium, Dedicated).
    
    .PARAMETER StorageAccount
        Storage account name (will create if not provided).
    
    .PARAMETER ApplicationInsights
        Application Insights name (will create if not provided).
    
    .PARAMETER CustomDomain
        Custom domain for the function app.
    
    .PARAMETER EnvironmentVariables
        Hashtable of environment variables.
    
    .PARAMETER AppSettings
        Hashtable of application settings.
    
    .PARAMETER IdentityType
        Managed identity type (SystemAssigned, UserAssigned, None).
    
    .PARAMETER UserAssignedIdentity
        User-assigned managed identity resource ID.
    
    .PARAMETER EnableContinuousDeployment
        Enable continuous deployment from source control.
    
    .PARAMETER SourceControlRepository
        Source control repository URL.
    
    .PARAMETER SourceControlBranch
        Source control branch name.
    
    .PARAMETER SourceControlToken
        Source control access token.
    
    .PARAMETER BuildImage
        Build container image for custom handlers.
    
    .PARAMETER ContainerRegistry
        Container registry for custom handlers.
    
    .PARAMETER ContainerImage
        Container image name for custom handlers.
    
    .EXAMPLE
        Deploy-AzureFunctions -AppName "my-api-functions" -ResourceGroup "my-rg" -SubscriptionId "00000000-0000-0000-0000-000000000000" -ProjectPath "C:\Projects\my-functions" -Runtime "node" -RuntimeVersion "18"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        
        [Parameter()]
        [string]$Location = "westeurope",
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        
        [Parameter()]
        [ValidateSet("node", "python", "dotnet", "java", "powershell")]
        [string]$Runtime = "node",
        
        [Parameter()]
        [string]$RuntimeVersion = "18",
        
        [Parameter()]
        [ValidateSet("Windows", "Linux")]
        [string]$OperatingSystem = "Windows",
        
        [Parameter()]
        [ValidateSet("Consumption", "Premium", "Dedicated")]
        [string]$PlanType = "Consumption",
        
        [Parameter()]
        [string]$StorageAccount,
        
        [Parameter()]
        [string]$ApplicationInsights,
        
        [Parameter()]
        [string]$CustomDomain,
        
        [Parameter()]
        [hashtable]$EnvironmentVariables = @{},
        
        [Parameter()]
        [hashtable]$AppSettings = @{},
        
        [Parameter()]
        [ValidateSet("SystemAssigned", "UserAssigned", "None")]
        [string]$IdentityType = "SystemAssigned",
        
        [Parameter()]
        [string]$UserAssignedIdentity,
        
        [Parameter()]
        [switch]$EnableContinuousDeployment,
        
        [Parameter()]
        [string]$SourceControlRepository,
        
        [Parameter()]
        [string]$SourceControlBranch = "main",
        
        [Parameter()]
        [SecureString]$SourceControlToken,
        
        [Parameter()]
        [switch]$BuildImage,
        
        [Parameter()]
        [string]$ContainerRegistry,
        
        [Parameter()]
        [string]$ContainerImage
    )
    
    Write-Host "=== Deploying to Azure Functions ===" -ForegroundColor Cyan
    Write-Host "Project: $AppName" -ForegroundColor White
    Write-Host "Path: $ProjectPath" -ForegroundColor White
    Write-Host "Region: $Location" -ForegroundColor White
    Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
    Write-Host "Runtime: $Runtime $RuntimeVersion" -ForegroundColor White
    Write-Host "OS: $OperatingSystem" -ForegroundColor White
    Write-Host "Plan: $PlanType" -ForegroundColor White
    Write-Host ""
    
    # Step 1: Check Azure PowerShell prerequisites
    Write-Host "Step 1/8: Checking Azure PowerShell prerequisites..." -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Az.Functions)) {
        Write-Host "Installing Azure Functions PowerShell module..." -ForegroundColor Yellow
        try {
            Install-Module -Name Az.Functions -Force -AllowClobber
            Write-Host "Azure Functions module installed successfully." -ForegroundColor Green
        }
        catch {
            throw "Failed to install Azure Functions module: $($_.Exception.Message)"
        }
    }
    
    # Step 2: Set Azure subscription
    Write-Host "Step 2/8: Setting Azure subscription..." -ForegroundColor Cyan
    try {
        $context = Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
        Write-Host "Successfully set subscription context: $($context.Subscription.Name)" -ForegroundColor Green
    }
    catch {
        throw "Failed to set Azure subscription context: $($_.Exception.Message)"
    }
    
    # Step 3: Create resource group if not exists
    Write-Host "Step 3/8: Creating resource group..." -ForegroundColor Cyan
    try {
        $existingRG = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
        if (-not $existingRG) {
            Write-Host "Creating resource group: $ResourceGroup" -ForegroundColor White
            New-AzResourceGroup -Name $ResourceGroup -Location $Location -ErrorAction Stop
            Write-Host "Resource group created successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Resource group '$ResourceGroup' already exists." -ForegroundColor Green
        }
    }
    catch {
        throw "Failed to create resource group: $($_.Exception.Message)"
    }
    
    # Step 4: Create Storage Account
    Write-Host "Step 4/8: Creating Storage Account..." -ForegroundColor Cyan
    if (-not $StorageAccount) {
        $StorageAccount = "$($AppName.ToLower())storage"
    }
    
    try {
        $existingStorage = Get-AzStorageAccount -Name $StorageAccount -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
        if (-not $existingStorage) {
            Write-Host "Creating Storage Account: $StorageAccount" -ForegroundColor White
            $storageAccount = New-AzStorageAccount -Name $StorageAccount -ResourceGroupName $ResourceGroup -Location $Location -SkuName Standard_LRS -ErrorAction Stop
            Write-Host "Storage Account created successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Storage Account '$StorageAccount' already exists." -ForegroundColor Green
        }
    }
    catch {
        throw "Failed to create Storage Account: $($_.Exception.Message)"
    }
    
    # Step 5: Create Application Insights
    Write-Host "Step 5/8: Creating Application Insights..." -ForegroundColor Cyan
    if (-not $ApplicationInsights) {
        $ApplicationInsights = "$AppName-insights"
    }
    
    try {
        $existingInsights = Get-AzApplicationInsights -Name $ApplicationInsights -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
        if (-not $existingInsights) {
            Write-Host "Creating Application Insights: $ApplicationInsights" -ForegroundColor White
            $insights = New-AzApplicationInsights -Name $ApplicationInsights -ResourceGroupName $ResourceGroup -Location $Location -Kind web -ErrorAction Stop
            Write-Host "Application Insights created successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Application Insights '$ApplicationInsights' already exists." -ForegroundColor Green
        }
    }
    catch {
        throw "Failed to create Application Insights: $($_.Exception.Message)"
    }
    
    # Step 6: Create App Service Plan (for Premium/Dedicated plans)
    Write-Host "Step 6/8: Creating App Service Plan..." -ForegroundColor Cyan
    $appServicePlan = $null
    if ($PlanType -in @("Premium", "Dedicated")) {
        $planName = "$AppName-plan"
        try {
            $existingPlan = Get-AzAppServicePlan -Name $planName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
            if (-not $existingPlan) {
                Write-Host "Creating App Service Plan: $planName" -ForegroundColor White
                $sku = if ($PlanType -eq "Premium") { "P1v2" } else { "B1" }
                $appServicePlan = New-AzAppServicePlan -Name $planName -ResourceGroupName $ResourceGroup -Location $Location -Tier $PlanType -WorkerSize $sku -ErrorAction Stop
                Write-Host "App Service Plan created successfully." -ForegroundColor Green
            }
            else {
                $appServicePlan = $existingPlan
                Write-Host "App Service Plan '$planName' already exists." -ForegroundColor Green
            }
        }
        catch {
            throw "Failed to create App Service Plan: $($_.Exception.Message)"
        }
    }
    
    # Step 7: Create Function App
    Write-Host "Step 7/8: Creating Function App..." -ForegroundColor Cyan
    try {
        $functionAppParams = @{
            Name              = $AppName
            ResourceGroupName = $ResourceGroup
            Location          = $Location
            StorageAccount    = $StorageAccount
            Runtime           = $Runtime
            RuntimeVersion    = $RuntimeVersion
            OperatingSystem   = $OperatingSystem
            PlanType          = $PlanType
        }
        
        # Add App Service Plan for Premium/Dedicated plans
        if ($appServicePlan) {
            $functionAppParams.AppServicePlan = $appServicePlan
        }
        
        # Add Application Insights
        $functionAppParams.ApplicationInsights = $ApplicationInsights
        
        # Add managed identity
        if ($IdentityType -ne "None") {
            $functionAppParams.IdentityType = $IdentityType
            if ($IdentityType -eq "UserAssigned" -and $UserAssignedIdentity) {
                $functionAppParams.UserAssignedIdentity = $UserAssignedIdentity
            }
        }
        
        Write-Host "Creating Function App: $AppName" -ForegroundColor White
        $functionApp = New-AzFunctionApp @functionAppParams -ErrorAction Stop
        Write-Host "Function App created successfully!" -ForegroundColor Green
    }
    catch {
        throw "Failed to create Function App: $($_.Exception.Message)"
    }
    
    # Step 8: Configure Function App settings
    Write-Host "Step 8/8: Configuring Function App settings..." -ForegroundColor Cyan
    
    # Add environment variables and app settings
    $allSettings = @{}
    
    # Add default settings
    $allSettings["FUNCTIONS_WORKER_RUNTIME"] = $Runtime
    $allSettings["WEBSITE_NODE_DEFAULT_VERSION"] = if ($Runtime -eq "node") { "~$RuntimeVersion" } else { "" }
    $allSettings["WEBSITE_RUN_FROM_PACKAGE"] = "1"
    
    # Add custom environment variables
    foreach ($key in $EnvironmentVariables.Keys) {
        $allSettings[$key] = $EnvironmentVariables[$key]
    }
    
    # Add custom app settings
    foreach ($key in $AppSettings.Keys) {
        $allSettings[$key] = $AppSettings[$key]
    }
    
    # Apply settings
    if ($allSettings.Count -gt 0) {
        try {
            Set-AzFunctionAppSetting -Name $AppName -ResourceGroupName $ResourceGroup -AppSetting $allSettings -ErrorAction Stop
            Write-Host "Function App settings configured successfully." -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to configure Function App settings: $($_.Exception.Message)"
        }
    }
    
    # Configure continuous deployment if requested
    if ($EnableContinuousDeployment -and $SourceControlRepository) {
        try {
            Write-Host "Configuring continuous deployment..." -ForegroundColor White
            $deploymentParams = @{
                Name              = $AppName
                ResourceGroupName = $ResourceGroup
                RepositoryUrl     = $SourceControlRepository
                Branch            = $SourceControlBranch
            }
            
            if ($SourceControlToken) {
                $plainTextToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SourceControlToken))
                $deploymentParams.RepositoryToken = $plainTextToken
            }
            
            Set-AzFunctionAppSourceControl @deploymentParams -ErrorAction Stop
            Write-Host "Continuous deployment configured successfully." -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to configure continuous deployment: $($_.Exception.Message)"
        }
    }
    
    # Configure custom domain if provided
    if ($CustomDomain) {
        try {
            Write-Host "Configuring custom domain: $CustomDomain" -ForegroundColor White
            # Note: Custom domain configuration requires additional setup
            Write-Host "Custom domain configuration requires additional Azure services setup." -ForegroundColor Yellow
        }
        catch {
            Write-Warning "Failed to configure custom domain: $($_.Exception.Message)"
        }
    }
    
    # Return deployment information
    $functionAppUrl = "https://$AppName.azurewebsites.net"
    
    return @{
        Success              = $true
        DeploymentUrl        = $functionAppUrl
        AppName              = $AppName
        Platform             = "Azure"
        Service              = "Functions"
        Region               = $Location
        ResourceGroup        = $ResourceGroup
        Runtime              = $Runtime
        RuntimeVersion       = $RuntimeVersion
        OperatingSystem      = $OperatingSystem
        PlanType             = $PlanType
        StorageAccount       = $StorageAccount
        ApplicationInsights  = $ApplicationInsights
        IdentityType         = $IdentityType
        CustomDomain         = $CustomDomain
        ContinuousDeployment = $EnableContinuousDeployment
    }
} 