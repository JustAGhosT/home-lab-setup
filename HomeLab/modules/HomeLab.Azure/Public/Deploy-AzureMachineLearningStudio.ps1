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
        
        # Check if resource group exists
        $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
        if ($rgExists -ne "true") {
            Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
            az group create --name $ResourceGroup --location $Location
        }
        
        # Generate default names if not provided
        if (-not $StorageAccountName) {
            $StorageAccountName = "$($WorkspaceName.ToLower())storage$(Get-Random -Minimum 1000 -Maximum 9999)"
        }
        
        if (-not $ApplicationInsightsName) {
            $ApplicationInsightsName = "$($WorkspaceName.ToLower())ai$(Get-Random -Minimum 1000 -Maximum 9999)"
        }
        
        if (-not $KeyVaultName) {
            $KeyVaultName = "$($WorkspaceName.ToLower())kv$(Get-Random -Minimum 1000 -Maximum 9999)"
        }
        
        # Create storage account
        Write-ColorOutput "Creating storage account: $StorageAccountName" -ForegroundColor Yellow
        $storageExists = az storage account show --name $StorageAccountName --resource-group $ResourceGroup --output tsv 2>$null
        if (-not $storageExists) {
            az storage account create `
                --name $StorageAccountName `
                --resource-group $ResourceGroup `
                --location $Location `
                --sku Standard_LRS `
                --kind StorageV2
        }
        
        # Create Application Insights
        Write-ColorOutput "Creating Application Insights: $ApplicationInsightsName" -ForegroundColor Yellow
        $aiExists = az monitor app-insights component show --app $ApplicationInsightsName --resource-group $ResourceGroup --output tsv 2>$null
        if (-not $aiExists) {
            az monitor app-insights component create `
                --app $ApplicationInsightsName `
                --location $Location `
                --resource-group $ResourceGroup `
                --application-type web
        }
        
        # Create Key Vault
        Write-ColorOutput "Creating Key Vault: $KeyVaultName" -ForegroundColor Yellow
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
        }
        
        # Create container registry if specified
        if ($ContainerRegistryName) {
            Write-ColorOutput "Creating container registry: $ContainerRegistryName" -ForegroundColor Yellow
            $acrExists = az acr show --name $ContainerRegistryName --resource-group $ResourceGroup --output tsv 2>$null
            if (-not $acrExists) {
                az acr create `
                    --name $ContainerRegistryName `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --sku Basic
            }
        }
        
        # Create Machine Learning workspace
        Write-ColorOutput "Creating Machine Learning workspace: $WorkspaceName" -ForegroundColor Yellow
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
        }
        
        # Get workspace details
        Write-ColorOutput "Getting workspace details..." -ForegroundColor Yellow
        $workspaceDetails = az ml workspace show `
            --name $WorkspaceName `
            --resource-group $ResourceGroup `
            --output json | ConvertFrom-Json
        
        # Get workspace access token
        $accessToken = az ml workspace get-access-token `
            --name $WorkspaceName `
            --resource-group $ResourceGroup `
            --query "accessToken" `
            --output tsv
        
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
        
        # Return deployment info
        return @{
            ResourceGroup           = $ResourceGroup
            WorkspaceName           = $WorkspaceName
            StorageAccountName      = $StorageAccountName
            ApplicationInsightsName = $ApplicationInsightsName
            KeyVaultName            = $KeyVaultName
            ContainerRegistryName   = $ContainerRegistryName
            WorkspaceId             = $workspaceDetails.id
            WorkspaceUrl            = $workspaceDetails.properties.workspaceUrl
            AccessToken             = $accessToken
            WorkspaceDetails        = $workspaceDetails
        }
    }
    catch {
        Write-ColorOutput "Error deploying Azure Machine Learning Studio: $_" -ForegroundColor Red
        throw
    }
} 