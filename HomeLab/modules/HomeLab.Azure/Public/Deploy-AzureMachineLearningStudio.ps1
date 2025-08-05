function Deploy-AzureMachineLearningStudio {
    <#
    .SYNOPSIS
        Deploys Azure Machine Learning Studio workspace.
    
    .DESCRIPTION
        Deploys Azure Machine Learning Studio workspace with configurable parameters including
        compute resources, storage accounts, and application insights.
    
    .PARAMETER ResourceGroup
        The resource group name where the ML workspace will be deployed.
    
    .PARAMETER Location
        The Azure location for the deployment.
    
    .PARAMETER WorkspaceName
        The name of the Machine Learning workspace.
    
    .PARAMETER StorageAccountName
        The name of the storage account for the workspace.
    
    .PARAMETER ApplicationInsightsName
        The name of the Application Insights resource.
    
    .PARAMETER KeyVaultName
        The name of the Key Vault for the workspace.
    
    .PARAMETER ContainerRegistryName
        The name of the container registry (optional).
    
    .PARAMETER EnableHbiWorkspace
        Whether to enable high business impact workspace.
    
    .PARAMETER EnableSoftDelete
        Whether to enable soft delete for Key Vault.
    
    .PARAMETER EnablePublicAccess
        Whether to enable public access for the workspace.
    
    .EXAMPLE
        Deploy-AzureMachineLearningStudio -ResourceGroup "my-rg" -Location "southafricanorth" -WorkspaceName "my-ml-workspace"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$Location,
        
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceName,
        
        [Parameter(Mandatory = $false)]
        [string]$StorageAccountName,
        
        [Parameter(Mandatory = $false)]
        [string]$ApplicationInsightsName,
        
        [Parameter(Mandatory = $false)]
        [string]$KeyVaultName,
        
        [Parameter(Mandatory = $false)]
        [string]$ContainerRegistryName,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableHbiWorkspace = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableSoftDelete = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnablePublicAccess = $false
    )
    
    try {
        Write-ColorOutput "Starting Azure Machine Learning Studio deployment..." -ForegroundColor Cyan
        
        # Validate Azure CLI availability and authentication
        if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
            throw "Azure CLI is not installed or not available in PATH. Please install Azure CLI from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        }
        
        try {
            $null = az account show --query id --output tsv 2>$null
            if ($LASTEXITCODE -ne 0) { throw "You are not logged in to Azure. Please run 'az login' to authenticate." }
        }
        catch { 
            throw "Azure authentication failed. Please run 'az login' to authenticate with Azure." 
        }
        
        # Check if resource group exists
        $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
        if ($rgExists -ne "true") {
            Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
            az group create --name $ResourceGroup --location $Location
        }
        
        # Generate default names if not provided using robust unique identifiers
        function Get-UniqueResourceSuffix {
            # Create a more robust unique identifier using timestamp and GUID
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $guidSegment = (New-Guid).ToString().Substring(0, 8)
            $randomSuffix = Get-Random -Minimum 100000 -Maximum 999999
            return "$timestamp$guidSegment$randomSuffix"
        }
        
        if (-not $StorageAccountName) {
            $uniqueSuffix = Get-UniqueResourceSuffix
            $StorageAccountName = "$($WorkspaceName.ToLower())storage$uniqueSuffix"
            # Ensure storage account name meets Azure requirements (3-24 chars, lowercase, numbers)
            if ($StorageAccountName.Length -gt 24) {
                $StorageAccountName = $StorageAccountName.Substring(0, 24)
            }
        }
        
        if (-not $ApplicationInsightsName) {
            $uniqueSuffix = Get-UniqueResourceSuffix
            $ApplicationInsightsName = "$($WorkspaceName.ToLower())ai$uniqueSuffix"
            # Application Insights names can be longer, but let's keep reasonable
            if ($ApplicationInsightsName.Length -gt 50) {
                $ApplicationInsightsName = $ApplicationInsightsName.Substring(0, 50)
            }
        }
        
        if (-not $KeyVaultName) {
            $uniqueSuffix = Get-UniqueResourceSuffix
            $KeyVaultName = "$($WorkspaceName.ToLower())kv$uniqueSuffix"
            # Key Vault names can be longer, but let's keep reasonable
            if ($KeyVaultName.Length -gt 50) {
                $KeyVaultName = $KeyVaultName.Substring(0, 50)
            }
        }
        
        # Create storage account
        Write-ColorOutput "Creating storage account: $StorageAccountName" -ForegroundColor Yellow
        try {
            $storageExists = az storage account show --name $StorageAccountName --resource-group $ResourceGroup --output tsv 2>$null
            if (-not $storageExists) {
                az storage account create `
                    --name $StorageAccountName `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --sku Standard_LRS `
                    --kind StorageV2
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create storage account '$StorageAccountName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created storage account: $StorageAccountName" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "Storage account '$StorageAccountName' already exists" -ForegroundColor Green
            }
        }
        catch {
            Write-ColorOutput "Error with storage account operations: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to handle storage account '$StorageAccountName': $($_.Exception.Message)"
        }
        
        # Create Application Insights
        Write-ColorOutput "Creating Application Insights: $ApplicationInsightsName" -ForegroundColor Yellow
        try {
            $aiExists = az monitor app-insights component show --app $ApplicationInsightsName --resource-group $ResourceGroup --output tsv 2>$null
            if (-not $aiExists) {
                az monitor app-insights component create `
                    --app $ApplicationInsightsName `
                    --location $Location `
                    --resource-group $ResourceGroup `
                    --application-type web
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Application Insights '$ApplicationInsightsName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Application Insights: $ApplicationInsightsName" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "Application Insights '$ApplicationInsightsName' already exists" -ForegroundColor Green
            }
        }
        catch {
            Write-ColorOutput "Error with Application Insights operations: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to handle Application Insights '$ApplicationInsightsName': $($_.Exception.Message)"
        }
        
        # Create Key Vault
        Write-ColorOutput "Creating Key Vault: $KeyVaultName" -ForegroundColor Yellow
        try {
            $kvExists = az keyvault show --name $KeyVaultName --resource-group $ResourceGroup --output tsv 2>$null
            if (-not $kvExists) {
                $kvParams = @(
                    "keyvault", "create",
                    "--name", $KeyVaultName,
                    "--resource-group", $ResourceGroup,
                    "--location", $Location
                )
                
                if ($EnableSoftDelete) {
                    $kvParams += "--enable-soft-delete"
                }
                
                az $kvParams
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Key Vault '$KeyVaultName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Key Vault: $KeyVaultName" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "Key Vault '$KeyVaultName' already exists" -ForegroundColor Green
            }
        }
        catch {
            Write-ColorOutput "Error with Key Vault operations: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to handle Key Vault '$KeyVaultName': $($_.Exception.Message)"
        }
        
        # Create container registry if specified
        if ($ContainerRegistryName) {
            Write-ColorOutput "Creating container registry: $ContainerRegistryName" -ForegroundColor Yellow
            try {
                $acrExists = az acr show --name $ContainerRegistryName --resource-group $ResourceGroup --output tsv 2>$null
                if (-not $acrExists) {
                    az acr create `
                        --name $ContainerRegistryName `
                        --resource-group $ResourceGroup `
                        --location $Location `
                        --sku Basic
                    
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to create container registry '$ContainerRegistryName'. Exit code: $LASTEXITCODE"
                    }
                    
                    Write-ColorOutput "Successfully created container registry: $ContainerRegistryName" -ForegroundColor Green
                }
                else {
                    Write-ColorOutput "Container registry '$ContainerRegistryName' already exists" -ForegroundColor Green
                }
            }
            catch {
                Write-ColorOutput "Error with container registry operations: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to handle container registry '$ContainerRegistryName': $($_.Exception.Message)"
            }
        }
        
        # Create Machine Learning workspace
        Write-ColorOutput "Creating Machine Learning workspace: $WorkspaceName" -ForegroundColor Yellow
        try {
            $workspaceExists = az ml workspace show --name $WorkspaceName --resource-group $ResourceGroup --output tsv 2>$null
            if (-not $workspaceExists) {
                $workspaceParams = @(
                    "ml", "workspace", "create",
                    "--name", $WorkspaceName,
                    "--resource-group", $ResourceGroup,
                    "--location", $Location,
                    "--storage-account", $StorageAccountName,
                    "--application-insights", $ApplicationInsightsName,
                    "--key-vault", $KeyVaultName
                )
                
                if ($ContainerRegistryName) {
                    $workspaceParams += "--container-registry"
                    $workspaceParams += $ContainerRegistryName
                }
                
                if ($EnableHbiWorkspace) {
                    $workspaceParams += "--hbi-workspace"
                }
                
                if ($EnablePublicAccess) {
                    $workspaceParams += "--public-network-access"
                    $workspaceParams += "Enabled"
                }
                
                az $workspaceParams
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Machine Learning workspace '$WorkspaceName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Machine Learning workspace: $WorkspaceName" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "Machine Learning workspace '$WorkspaceName' already exists" -ForegroundColor Green
            }
        }
        catch {
            Write-ColorOutput "Error with Machine Learning workspace operations: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to handle Machine Learning workspace '$WorkspaceName': $($_.Exception.Message)"
        }
        
        # Get workspace details
        Write-ColorOutput "Getting workspace details..." -ForegroundColor Yellow
        try {
            $workspaceDetails = az ml workspace show `
                --name $WorkspaceName `
                --resource-group $ResourceGroup `
                --output json | ConvertFrom-Json
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve workspace details. Exit code: $LASTEXITCODE"
            }
            
            if (-not $workspaceDetails) {
                throw "Workspace details are empty or null. Please check if the workspace was created successfully."
            }
            
            Write-ColorOutput "Successfully retrieved workspace details" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving workspace details: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve workspace details for '$WorkspaceName': $($_.Exception.Message)"
        }
        
        # Get workspace access token securely
        Write-ColorOutput "Retrieving workspace access token securely..." -ForegroundColor Yellow
        try {
            $accessToken = az ml workspace get-access-token `
                --name $WorkspaceName `
                --resource-group $ResourceGroup `
                --query "accessToken" `
                --output tsv
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve access token. Exit code: $LASTEXITCODE"
            }
            
            if ([string]::IsNullOrWhiteSpace($accessToken)) {
                throw "Access token is empty or null. Please check if the workspace was created successfully and you have proper permissions."
            }
            
            Write-ColorOutput "Successfully retrieved workspace access token" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving access token: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve access token for workspace '$WorkspaceName': $($_.Exception.Message)"
        }
        
        # Display deployment summary
        Write-ColorOutput "`nAzure Machine Learning Studio deployment completed successfully!" -ForegroundColor Green
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "Workspace Name: $WorkspaceName" -ForegroundColor Gray
        Write-ColorOutput "Storage Account: $StorageAccountName" -ForegroundColor Gray
        Write-ColorOutput "Application Insights: $ApplicationInsightsName" -ForegroundColor Gray
        Write-ColorOutput "Key Vault: $KeyVaultName" -ForegroundColor Gray
        if ($ContainerRegistryName) {
            Write-ColorOutput "Container Registry: $ContainerRegistryName" -ForegroundColor Gray
        }
        Write-ColorOutput "Workspace ID: $($workspaceDetails.id)" -ForegroundColor Gray
        Write-ColorOutput "Workspace URL: $($workspaceDetails.properties.workspaceUrl)" -ForegroundColor Gray
        
        # Helper function to mask sensitive tokens
        function Get-MaskedToken {
            param([string]$Token, [int]$VisibleChars = 8)
            if ([string]::IsNullOrEmpty($Token)) {
                return "[NOT SET]"
            }
            if ($Token.Length -le $VisibleChars) {
                return "*" * $Token.Length
            }
            return "*" * ($Token.Length - $VisibleChars) + $Token.Substring($Token.Length - $VisibleChars)
        }
        
        # Display masked access token for security
        Write-ColorOutput "Access Token: $(Get-MaskedToken -Token $accessToken)" -ForegroundColor Gray
        
        # Security warning for sensitive data
        Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
        Write-ColorOutput "The returned object contains sensitive ML workspace access tokens." -ForegroundColor Yellow
        Write-ColorOutput "Please ensure this data is:" -ForegroundColor Yellow
        Write-ColorOutput "  • Not logged or written to files" -ForegroundColor Yellow
        Write-ColorOutput "  • Not committed to version control" -ForegroundColor Yellow
        Write-ColorOutput "  • Stored securely in production environments" -ForegroundColor Yellow
        Write-ColorOutput "  • Considered for Azure Key Vault integration" -ForegroundColor Yellow
        
        # Return deployment info with secure token reference
        return @{
            ResourceGroup           = $ResourceGroup
            WorkspaceName           = $WorkspaceName
            StorageAccountName      = $StorageAccountName
            ApplicationInsightsName = $ApplicationInsightsName
            KeyVaultName            = $KeyVaultName
            ContainerRegistryName   = $ContainerRegistryName
            WorkspaceId             = $workspaceDetails.id
            WorkspaceUrl            = $workspaceDetails.properties.workspaceUrl
            AccessToken             = $accessToken  # Keep for immediate use, but warn about security
            WorkspaceDetails        = $workspaceDetails
        }
    }
    catch {
        Write-ColorOutput "Error deploying Azure Machine Learning Studio: $_" -ForegroundColor Red
        throw
    }
} 