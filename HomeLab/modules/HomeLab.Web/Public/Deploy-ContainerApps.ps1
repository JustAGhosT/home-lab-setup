function Deploy-ContainerApps {
    <#
    .SYNOPSIS
        Deploys applications to Azure Container Apps (serverless containers).
    
    .DESCRIPTION
        This function deploys containerized applications to Azure Container Apps, which provides
        serverless container orchestration with automatic scaling, HTTPS endpoints, and Dapr integration.
    
    .PARAMETER AppName
        Application name for the Container App.
    
    .PARAMETER ResourceGroup
        Azure Resource Group name.
    
    .PARAMETER Location
        Azure region for deployment.
    
    .PARAMETER SubscriptionId
        Azure subscription ID.
    
    .PARAMETER ProjectPath
        Path to the project directory containing Dockerfile.
    
    .PARAMETER ImageName
        Container image name (optional, will auto-generate if not provided).
    
    .PARAMETER ContainerRegistry
        Container registry URL (ACR, Docker Hub, etc.).
    
    .PARAMETER RegistryUsername
        Container registry username.
    
    .PARAMETER RegistryPassword
        Container registry password.
    
    .PARAMETER Environment
        Container Apps Environment name (will create if not exists).
    
    .PARAMETER Replicas
        Number of replicas (0-300, 0 for scale to zero).
    
    .PARAMETER Cpu
        CPU allocation (0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0).
    
    .PARAMETER Memory
        Memory allocation (0.5Gi, 1Gi, 2Gi, 3Gi, 4Gi, 5Gi, 6Gi, 7Gi, 8Gi).
    
    .PARAMETER Port
        Container port (default: 80).
    
    .PARAMETER Ingress
        Ingress type (external, internal, disabled).
    
    .PARAMETER TargetPort
        Target port for ingress (default: 80).
    
    .PARAMETER CustomDomain
        Custom domain for the application.
    
    .PARAMETER EnvironmentVariables
        Hashtable of environment variables.
    
    .PARAMETER Secrets
        Hashtable of secrets.
    
    .PARAMETER DaprEnabled
        Enable Dapr for the container app.
    
    .PARAMETER DaprAppId
        Dapr application ID.
    
    .PARAMETER DaprAppPort
        Dapr application port.
    
    .PARAMETER BuildImage
        Build container image locally before deployment.
    
    .PARAMETER PushImage
        Push image to container registry.
    
    .EXAMPLE
        Deploy-ContainerApps -AppName "my-api" -ResourceGroup "my-rg" -SubscriptionId "00000000-0000-0000-0000-000000000000" -ProjectPath "C:\Projects\my-api"
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
        [string]$ImageName,
        
        [Parameter()]
        [string]$ContainerRegistry,
        
        [Parameter()]
        [string]$RegistryUsername,
        
        [Parameter()]
        [SecureString]$RegistryPassword,
        
        [Parameter()]
        [string]$Environment,
        
        [Parameter()]
        [int]$Replicas = 1,
        
        [Parameter()]
        [ValidateSet("0.25", "0.5", "0.75", "1.0", "1.25", "1.5", "1.75", "2.0")]
        [string]$Cpu = "1.0",
        
        [Parameter()]
        [ValidateSet("0.5Gi", "1Gi", "2Gi", "3Gi", "4Gi", "5Gi", "6Gi", "7Gi", "8Gi")]
        [string]$Memory = "2Gi",
        
        [Parameter()]
        [int]$Port = 80,
        
        [Parameter()]
        [ValidateSet("external", "internal", "disabled")]
        [string]$Ingress = "external",
        
        [Parameter()]
        [int]$TargetPort = 80,
        
        [Parameter()]
        [string]$CustomDomain,
        
        [Parameter()]
        [hashtable]$EnvironmentVariables = @{},
        
        [Parameter()]
        [hashtable]$Secrets = @{},
        
        [Parameter()]
        [switch]$DaprEnabled,
        
        [Parameter()]
        [string]$DaprAppId,
        
        [Parameter()]
        [int]$DaprAppPort = 80,
        
        [Parameter()]
        [switch]$BuildImage,
        
        [Parameter()]
        [switch]$PushImage
    )
    
    Write-Host "=== Deploying to Azure Container Apps ===" -ForegroundColor Cyan
    Write-Host "Project: $AppName" -ForegroundColor White
    Write-Host "Path: $ProjectPath" -ForegroundColor White
    Write-Host "Region: $Location" -ForegroundColor White
    Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
    Write-Host ""
    
    # Step 1: Check Azure PowerShell prerequisites
    Write-Host "Step 1/8: Checking Azure PowerShell prerequisites..." -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Az.ContainerApps)) {
        Write-Host "Installing Azure Container Apps PowerShell module..." -ForegroundColor Yellow
        try {
            Install-Module -Name Az.ContainerApps -Force -AllowClobber
            Write-Host "Azure Container Apps module installed successfully." -ForegroundColor Green
        }
        catch {
            throw "Failed to install Azure Container Apps module: $($_.Exception.Message)"
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
    
    # Step 4: Build and push container image if requested
    Write-Host "Step 4/8: Building and pushing container image..." -ForegroundColor Cyan
    if ($BuildImage) {
        if (-not (Test-Path -Path "$ProjectPath\Dockerfile")) {
            Write-Host "No Dockerfile found. Creating a basic Dockerfile..." -ForegroundColor Yellow
            $dockerfileContent = @"
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE $Port
CMD ["npm", "start"]
"@
            Set-Content -Path "$ProjectPath\Dockerfile" -Value $dockerfileContent
            Write-Host "Created basic Dockerfile." -ForegroundColor Green
        }
        
        if (-not $ImageName) {
            $ImageName = "$AppName:latest"
        }
        
        if (-not $ContainerRegistry) {
            # Use Azure Container Registry
            $acrName = "$($AppName.ToLower())acr"
            Write-Host "Creating Azure Container Registry: $acrName" -ForegroundColor White
            try {
                $acr = New-AzContainerRegistry -Name $acrName -ResourceGroupName $ResourceGroup -Location $Location -Sku Basic -ErrorAction Stop
                $ContainerRegistry = $acr.LoginServer
                Write-Host "Azure Container Registry created: $ContainerRegistry" -ForegroundColor Green
            }
            catch {
                throw "Failed to create Azure Container Registry: $($_.Exception.Message)"
            }
        }
        
        # Build image
        Write-Host "Building container image: $ImageName" -ForegroundColor White
        try {
            Push-Location -Path $ProjectPath
            docker build -t $ImageName .
            Write-Host "Container image built successfully." -ForegroundColor Green
        }
        catch {
            throw "Failed to build container image: $($_.Exception.Message)"
        }
        finally {
            Pop-Location
        }
        
        # Push image if requested
        if ($PushImage) {
            Write-Host "Pushing container image to registry..." -ForegroundColor White
            try {
                docker tag $ImageName "$ContainerRegistry/$ImageName"
                docker push "$ContainerRegistry/$ImageName"
                Write-Host "Container image pushed successfully." -ForegroundColor Green
            }
            catch {
                throw "Failed to push container image: $($_.Exception.Message)"
            }
        }
    }
    
    # Step 5: Create Container Apps Environment
    Write-Host "Step 5/8: Creating Container Apps Environment..." -ForegroundColor Cyan
    if (-not $Environment) {
        $Environment = "$AppName-env"
    }
    
    try {
        $existingEnv = Get-AzContainerAppEnvironment -Name $Environment -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
        if (-not $existingEnv) {
            Write-Host "Creating Container Apps Environment: $Environment" -ForegroundColor White
            $env = New-AzContainerAppEnvironment -Name $Environment -ResourceGroupName $ResourceGroup -Location $Location -ErrorAction Stop
            Write-Host "Container Apps Environment created successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Container Apps Environment '$Environment' already exists." -ForegroundColor Green
        }
    }
    catch {
        throw "Failed to create Container Apps Environment: $($_.Exception.Message)"
    }
    
    # Step 6: Configure container registry credentials
    Write-Host "Step 6/8: Configuring container registry credentials..." -ForegroundColor Cyan
    if ($ContainerRegistry -and $RegistryUsername -and $RegistryPassword) {
        try {
            $plainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($RegistryPassword))
            
            $registryCredential = @{
                Server   = $ContainerRegistry
                Username = $RegistryUsername
                Password = $plainTextPassword
            }
            
            Write-Host "Container registry credentials configured." -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to configure container registry credentials: $($_.Exception.Message)"
        }
    }
    
    # Step 7: Create Container App
    Write-Host "Step 7/8: Creating Container App..." -ForegroundColor Cyan
    try {
        $containerAppParams = @{
            Name              = $AppName
            ResourceGroupName = $ResourceGroup
            Location          = $Location
            EnvironmentId     = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.App/managedEnvironments/$Environment"
            Template          = @{
                containers = @(
                    @{
                        name      = $AppName
                        image     = if ($ContainerRegistry) { "$ContainerRegistry/$ImageName" } else { $ImageName }
                        resources = @{
                            cpu    = [double]$Cpu
                            memory = $Memory
                        }
                        ports     = @(
                            @{
                                port = $Port
                            }
                        )
                    }
                )
                scale      = @{
                    minReplicas = $Replicas
                    maxReplicas = if ($Replicas -eq 0) { 0 } else { [Math]::Max($Replicas * 3, 10) }
                }
            }
        }
        
        # Add ingress configuration
        if ($Ingress -ne "disabled") {
            $containerAppParams.Template.ingress = @{
                external      = ($Ingress -eq "external")
                targetPort    = $TargetPort
                allowInsecure = $false
            }
        }
        
        # Add environment variables
        if ($EnvironmentVariables.Count -gt 0) {
            $containerAppParams.Template.containers[0].env = @()
            foreach ($key in $EnvironmentVariables.Keys) {
                $containerAppParams.Template.containers[0].env += @{
                    name  = $key
                    value = $EnvironmentVariables[$key]
                }
            }
        }
        
        # Add secrets
        if ($Secrets.Count -gt 0) {
            $containerAppParams.Template.secrets = @()
            foreach ($key in $Secrets.Keys) {
                $containerAppParams.Template.secrets += @{
                    name  = $key
                    value = $Secrets[$key]
                }
            }
        }
        
        # Add Dapr configuration
        if ($DaprEnabled) {
            $containerAppParams.Template.dapr = @{
                enabled = $true
                appId   = if ($DaprAppId) { $DaprAppId } else { $AppName }
                appPort = $DaprAppPort
            }
        }
        
        Write-Host "Creating Container App: $AppName" -ForegroundColor White
        $containerApp = New-AzContainerApp @containerAppParams -ErrorAction Stop
        Write-Host "Container App created successfully!" -ForegroundColor Green
    }
    catch {
        throw "Failed to create Container App: $($_.Exception.Message)"
    }
    
    # Step 8: Configure custom domain if provided
    Write-Host "Step 8/8: Configuring custom domain..." -ForegroundColor Cyan
    if ($CustomDomain) {
        try {
            Write-Host "Configuring custom domain: $CustomDomain" -ForegroundColor White
            # Note: Custom domain configuration for Container Apps requires additional setup
            # This would typically involve Azure Front Door or Application Gateway
            Write-Host "Custom domain configuration requires additional Azure services setup." -ForegroundColor Yellow
        }
        catch {
            Write-Warning "Failed to configure custom domain: $($_.Exception.Message)"
        }
    }
    
    # Return deployment information
    $deploymentUrl = if ($Ingress -ne "disabled") { "https://$AppName.$($containerApp.Properties.Configuration.Ingress.Fqdn)" } else { "N/A" }
    
    return @{
        Success       = $true
        DeploymentUrl = $deploymentUrl
        AppName       = $AppName
        Platform      = "Azure"
        Service       = "Container Apps"
        Region        = $Location
        ResourceGroup = $ResourceGroup
        Environment   = $Environment
        ImageName     = if ($ContainerRegistry) { "$ContainerRegistry/$ImageName" } else { $ImageName }
        Replicas      = $Replicas
        Cpu           = $Cpu
        Memory        = $Memory
        DaprEnabled   = $DaprEnabled
        CustomDomain  = $CustomDomain
    }
} 