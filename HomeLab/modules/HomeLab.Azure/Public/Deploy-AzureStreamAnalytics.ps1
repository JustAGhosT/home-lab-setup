function Deploy-AzureStreamAnalytics {
    <#
    .SYNOPSIS
        Deploys Azure Stream Analytics.
    
    .DESCRIPTION
        Deploys Azure Stream Analytics with configurable parameters including
        streaming units, input/output configurations, and query definitions.
    
    .PARAMETER ResourceGroup
        The resource group name where the Stream Analytics job will be deployed.
    
    .PARAMETER Location
        The Azure location for the deployment.
    
    .PARAMETER JobName
        The name of the Stream Analytics job.
    
    .PARAMETER StreamingUnits
        The number of streaming units (1-192).
    
    .PARAMETER InputType
        The type of input (EventHub, IoTHub, Blob, etc.).
    
    .PARAMETER InputName
        The name of the input source.
    
    .PARAMETER OutputType
        The type of output (EventHub, Blob, SQL, etc.).
    
    .PARAMETER OutputName
        The name of the output destination.
    
    .PARAMETER Query
        The Stream Analytics query (optional).
    
    .PARAMETER EnableJobStart
        Whether to start the job after creation.
    
    .PARAMETER EnableContentLogging
        Whether to enable content logging.
    
    .EXAMPLE
        Deploy-AzureStreamAnalytics -ResourceGroup "my-rg" -Location "southafricanorth" -JobName "my-stream-job"
    
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
        [string]$JobName,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 192)]
        [int]$StreamingUnits = 1,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("EventHub", "IoTHub", "Blob", "PowerBI", "DataLake")]
        [string]$InputType = "EventHub",
        
        [Parameter(Mandatory = $false)]
        [string]$InputName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("EventHub", "Blob", "SQL", "CosmosDB", "PowerBI", "DataLake")]
        [string]$OutputType = "Blob",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputName,
        
        [Parameter(Mandatory = $false)]
        [string]$Query,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableJobStart = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableContentLogging = $false
    )
    
    try {
        Write-ColorOutput "Starting Azure Stream Analytics deployment..." -ForegroundColor Cyan
        
        # Check if resource group exists
        $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
        if ($rgExists -ne "true") {
            Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
            az group create --name $ResourceGroup --location $Location
        }
        
        # Generate default names if not provided
        if (-not $InputName) {
            $InputName = "$($JobName.ToLower())input$(Get-Random -Minimum 1000 -Maximum 9999)"
        }
        
        if (-not $OutputName) {
            $OutputName = "$($JobName.ToLower())output$(Get-Random -Minimum 1000 -Maximum 9999)"
        }
        
        # Create Stream Analytics job
        Write-ColorOutput "Creating Stream Analytics job: $JobName" -ForegroundColor Yellow
        $jobExists = az stream-analytics job show --name $JobName --resource-group $ResourceGroup --output tsv 2>$null
        if (-not $jobExists) {
            az stream-analytics job create `
                --name $JobName `
                --resource-group $ResourceGroup `
                --location $Location `
                --streaming-units $StreamingUnits
        }
        
        # Create input source
        Write-ColorOutput "Creating input source: $InputName" -ForegroundColor Yellow
        $inputExists = az stream-analytics input show --name $InputName --job-name $JobName --resource-group $ResourceGroup --output tsv 2>$null
        if (-not $inputExists) {
            switch ($InputType) {
                "EventHub" {
                    # Create Event Hub if it doesn't exist
                    $eventHubNamespace = "$($JobName.ToLower())ehns$(Get-Random -Minimum 1000 -Maximum 9999)"
                    $eventHubName = "$($JobName.ToLower())eh$(Get-Random -Minimum 1000 -Maximum 9999)"
                    
                    $ehnsExists = az eventhubs namespace show --name $eventHubNamespace --resource-group $ResourceGroup --output tsv 2>$null
                    if (-not $ehnsExists) {
                        az eventhubs namespace create `
                            --name $eventHubNamespace `
                            --resource-group $ResourceGroup `
                            --location $Location `
                            --sku Standard
                    }
                    
                    $ehExists = az eventhubs eventhub show --name $eventHubName --namespace-name $eventHubNamespace --resource-group $ResourceGroup --output tsv 2>$null
                    if (-not $ehExists) {
                        az eventhubs eventhub create `
                            --name $eventHubName `
                            --namespace-name $eventHubNamespace `
                            --resource-group $ResourceGroup
                    }
                    
                    # Create Stream Analytics input
                    az stream-analytics input create `
                        --name $InputName `
                        --job-name $JobName `
                        --resource-group $ResourceGroup `
                        --type Stream `
                        --datasource Microsoft.ServiceBus/EventHub `
                        --eventhub-namespace $eventHubNamespace `
                        --eventhub-name $eventHubName `
                        --shared-access-policy-name RootManageSharedAccessKey
                }
                
                "Blob" {
                    # Create storage account if it doesn't exist
                    $storageAccountName = "$($JobName.ToLower())storage$(Get-Random -Minimum 1000 -Maximum 9999)"
                    $containerName = "input"
                    
                    $storageExists = az storage account show --name $storageAccountName --resource-group $ResourceGroup --output tsv 2>$null
                    if (-not $storageExists) {
                        az storage account create `
                            --name $storageAccountName `
                            --resource-group $ResourceGroup `
                            --location $Location `
                            --sku Standard_LRS
                    }
                    
                    $storageKey = az storage account keys list `
                        --account-name $storageAccountName `
                        --resource-group $ResourceGroup `
                        --query "[0].value" `
                        --output tsv
                    
                    $containerExists = az storage container show --name $containerName --account-name $storageAccountName --account-key $storageKey --output tsv 2>$null
                    if (-not $containerExists) {
                        az storage container create `
                            --name $containerName `
                            --account-name $storageAccountName `
                            --account-key $storageKey
                    }
                    
                    # Create Stream Analytics input
                    az stream-analytics input create `
                        --name $InputName `
                        --job-name $JobName `
                        --resource-group $ResourceGroup `
                        --type Stream `
                        --datasource Microsoft.Storage/Blob `
                        --storage-accounts name=$storageAccountName account-key=$storageKey `
                        --container $containerName `
                        --path-pattern "{date}/{time}"
                }
                
                default {
                    Write-ColorOutput "Input type $InputType not yet implemented. Creating placeholder input." -ForegroundColor Yellow
                    # Create a placeholder input
                    az stream-analytics input create `
                        --name $InputName `
                        --job-name $JobName `
                        --resource-group $ResourceGroup `
                        --type Stream `
                        --datasource Microsoft.ServiceBus/EventHub `
                        --eventhub-namespace "placeholder" `
                        --eventhub-name "placeholder" `
                        --shared-access-policy-name RootManageSharedAccessKey
                }
            }
        }
        
        # Create output destination
        Write-ColorOutput "Creating output destination: $OutputName" -ForegroundColor Yellow
        $outputExists = az stream-analytics output show --name $OutputName --job-name $JobName --resource-group $ResourceGroup --output tsv 2>$null
        if (-not $outputExists) {
            switch ($OutputType) {
                "Blob" {
                    # Use existing storage account or create new one
                    $storageAccountName = "$($JobName.ToLower())outputstorage$(Get-Random -Minimum 1000 -Maximum 9999)"
                    $containerName = "output"
                    
                    $storageExists = az storage account show --name $storageAccountName --resource-group $ResourceGroup --output tsv 2>$null
                    if (-not $storageExists) {
                        az storage account create `
                            --name $storageAccountName `
                            --resource-group $ResourceGroup `
                            --location $Location `
                            --sku Standard_LRS
                    }
                    
                    $storageKey = az storage account keys list `
                        --account-name $storageAccountName `
                        --resource-group $ResourceGroup `
                        --query "[0].value" `
                        --output tsv
                    
                    $containerExists = az storage container show --name $containerName --account-name $storageAccountName --account-key $storageKey --output tsv 2>$null
                    if (-not $containerExists) {
                        az storage container create `
                            --name $containerName `
                            --account-name $storageAccountName `
                            --account-key $storageKey
                    }
                    
                    # Create Stream Analytics output
                    az stream-analytics output create `
                        --name $OutputName `
                        --job-name $JobName `
                        --resource-group $ResourceGroup `
                        --datasource Microsoft.Storage/Blob `
                        --storage-accounts name=$storageAccountName account-key=$storageKey `
                        --container $containerName `
                        --path-pattern "{date}/{time}" `
                        --serialization Microsoft.StreamAnalytics/JSON
                }
                
                default {
                    Write-ColorOutput "Output type $OutputType not yet implemented. Creating placeholder output." -ForegroundColor Yellow
                    # Create a placeholder output
                    az stream-analytics output create `
                        --name $OutputName `
                        --job-name $JobName `
                        --resource-group $ResourceGroup `
                        --datasource Microsoft.Storage/Blob `
                        --storage-accounts name="placeholder" account-key="placeholder" `
                        --container "placeholder" `
                        --path-pattern "{date}/{time}" `
                        --serialization Microsoft.StreamAnalytics/JSON
                }
            }
        }
        
        # Set query if provided
        if ($Query) {
            Write-ColorOutput "Setting Stream Analytics query..." -ForegroundColor Yellow
            az stream-analytics job update `
                --name $JobName `
                --resource-group $ResourceGroup `
                --transformation-query $Query
        }
        
        # Start job if requested
        if ($EnableJobStart) {
            Write-ColorOutput "Starting Stream Analytics job..." -ForegroundColor Yellow
            az stream-analytics job start `
                --name $JobName `
                --resource-group $ResourceGroup
        }
        
        # Get job details
        Write-ColorOutput "Getting job details..." -ForegroundColor Yellow
        $jobDetails = az stream-analytics job show `
            --name $JobName `
            --resource-group $ResourceGroup `
            --output json | ConvertFrom-Json
        
        # Display deployment summary
        Write-ColorOutput "`nAzure Stream Analytics deployment completed successfully!" -ForegroundColor Green
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "Job Name: $JobName" -ForegroundColor Gray
        Write-ColorOutput "Streaming Units: $StreamingUnits" -ForegroundColor Gray
        Write-ColorOutput "Input Type: $InputType" -ForegroundColor Gray
        Write-ColorOutput "Input Name: $InputName" -ForegroundColor Gray
        Write-ColorOutput "Output Type: $OutputType" -ForegroundColor Gray
        Write-ColorOutput "Output Name: $OutputName" -ForegroundColor Gray
        Write-ColorOutput "Job Status: $($jobDetails.properties.jobState)" -ForegroundColor Gray
        Write-ColorOutput "Job ID: $($jobDetails.id)" -ForegroundColor Gray
        
        # Return deployment info
        return @{
            ResourceGroup  = $ResourceGroup
            JobName        = $JobName
            StreamingUnits = $StreamingUnits
            InputType      = $InputType
            InputName      = $InputName
            OutputType     = $OutputType
            OutputName     = $OutputName
            Query          = $Query
            JobStatus      = $jobDetails.properties.jobState
            JobId          = $jobDetails.id
            JobDetails     = $jobDetails
        }
    }
    catch {
        Write-ColorOutput "Error deploying Azure Stream Analytics: $_" -ForegroundColor Red
        throw
    }
} 