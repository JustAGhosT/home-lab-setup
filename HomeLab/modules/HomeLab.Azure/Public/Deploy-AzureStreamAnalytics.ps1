function Deploy-AzureStreamAnalyticsJob {
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
         Deploy-AzureStreamAnalyticsJob -ResourceGroup "my-rg" -Location "southafricanorth" -JobName "my-stream-job"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
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
        [ValidateSet("EventHub", "Blob")]
        [string]$InputType = "EventHub",
        
        [Parameter(Mandatory = $false)]
        [string]$InputName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Blob")]
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
        try {
            $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
            if ($rgExists -ne "true") {
                Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
                az group create --name $ResourceGroup --location $Location
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create resource group '$ResourceGroup'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created resource group: $ResourceGroup" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "Resource group already exists: $ResourceGroup" -ForegroundColor Green
            }
        }
        catch {
            Write-ColorOutput "Error with resource group operations: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to handle resource group '$ResourceGroup': $($_.Exception.Message)"
        }
        
        # Generate default names if not provided
        if (-not $InputName) {
            $InputName = "$($JobName.ToLower())input$(Get-Random -Minimum 100000 -Maximum 999999)"
        }
        
        if (-not $OutputName) {
            $OutputName = "$($JobName.ToLower())output$(Get-Random -Minimum 100000 -Maximum 999999)"
        }
        
        # Create Stream Analytics job
        Write-ColorOutput "Creating Stream Analytics job: $JobName" -ForegroundColor Yellow
        try {
            # Check if job exists with proper error handling
            $jobExists = az stream-analytics job show --name $JobName --resource-group $ResourceGroup --output tsv 2>$null
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "Job does not exist, creating new Stream Analytics job..." -ForegroundColor Yellow
                
                # Create the Stream Analytics job
                az stream-analytics job create `
                    --name $JobName `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --streaming-units $StreamingUnits
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Stream Analytics job '$JobName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Stream Analytics job: $JobName" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "Stream Analytics job already exists: $JobName" -ForegroundColor Green
            }
        }
        catch {
            Write-ColorOutput "Error with Stream Analytics job operations: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to handle Stream Analytics job '$JobName': $($_.Exception.Message)"
        }
        
        # Create input source
        Write-ColorOutput "Creating input source: $InputName" -ForegroundColor Yellow
        try {
            # Check if input exists with proper error handling
            $inputExists = az stream-analytics input show --name $InputName --job-name $JobName --resource-group $ResourceGroup --output tsv 2>$null
            
            if ($LASTEXITCODE -ne 0) {
                switch ($InputType) {
                    "EventHub" {
                        # Create Event Hub if it doesn't exist
                        # Generate valid Event Hub namespace and hub names that meet Azure requirements
                        $cleanJobName = $JobName.ToLower() -replace '[^a-z0-9]', '' -replace '^[0-9]', 'a'
                        if ($cleanJobName.Length -gt 20) {
                            $cleanJobName = $cleanJobName.Substring(0, 20)
                        }
                        
                        $eventHubNamespace = "$($cleanJobName)ehns$(Get-Random -Minimum 100000 -Maximum 999999)"
                        $eventHubName = "$($cleanJobName)eh$(Get-Random -Minimum 100000 -Maximum 999999)"
                        
                        # Ensure names meet Azure Event Hub requirements (6-50 characters, alphanumeric and hyphens)
                        if ($eventHubNamespace.Length -gt 50) {
                            $eventHubNamespace = $eventHubNamespace.Substring(0, 50)
                        }
                        if ($eventHubName.Length -gt 50) {
                            $eventHubName = $eventHubName.Substring(0, 50)
                        }
                    
                        # Check and create Event Hub namespace
                        try {
                            $ehnsExists = az eventhubs namespace show --name $eventHubNamespace --resource-group $ResourceGroup --output tsv 2>$null
                            if (-not $ehnsExists) {
                                az eventhubs namespace create `
                                    --name $eventHubNamespace `
                                    --resource-group $ResourceGroup `
                                    --location $Location `
                                    --sku Standard
                            
                                if ($LASTEXITCODE -ne 0) {
                                    throw "Failed to create Event Hub namespace '$eventHubNamespace'. Exit code: $LASTEXITCODE"
                                }
                            
                                Write-ColorOutput "Successfully created Event Hub namespace: $eventHubNamespace" -ForegroundColor Green
                            }
                            else {
                                Write-ColorOutput "Event Hub namespace already exists: $eventHubNamespace" -ForegroundColor Green
                            }
                        }
                        catch {
                            Write-ColorOutput "Error with Event Hub namespace operations: $($_.Exception.Message)" -ForegroundColor Red
                            throw "Failed to handle Event Hub namespace '$eventHubNamespace': $($_.Exception.Message)"
                        }
                    
                        # Check and create Event Hub
                        try {
                            $ehExists = az eventhubs eventhub show --name $eventHubName --namespace-name $eventHubNamespace --resource-group $ResourceGroup --output tsv 2>$null
                            if (-not $ehExists) {
                                az eventhubs eventhub create `
                                    --name $eventHubName `
                                    --namespace-name $eventHubNamespace `
                                    --resource-group $ResourceGroup
                            
                                if ($LASTEXITCODE -ne 0) {
                                    throw "Failed to create Event Hub '$eventHubName'. Exit code: $LASTEXITCODE"
                                }
                            
                                Write-ColorOutput "Successfully created Event Hub: $eventHubName" -ForegroundColor Green
                            }
                            else {
                                Write-ColorOutput "Event Hub already exists: $eventHubName" -ForegroundColor Green
                            }
                        }
                        catch {
                            Write-ColorOutput "Error with Event Hub operations: $($_.Exception.Message)" -ForegroundColor Red
                            throw "Failed to handle Event Hub '$eventHubName': $($_.Exception.Message)"
                        }
                    
                        # Create Stream Analytics input
                        try {
                            az stream-analytics input create `
                                --name $InputName `
                                --job-name $JobName `
                                --resource-group $ResourceGroup `
                                --type Stream `
                                --datasource Microsoft.ServiceBus/EventHub `
                                --eventhub-namespace $eventHubNamespace `
                                --eventhub-name $eventHubName `
                                --shared-access-policy-name RootManageSharedAccessKey
                        
                            if ($LASTEXITCODE -ne 0) {
                                throw "Failed to create Stream Analytics input '$InputName'. Exit code: $LASTEXITCODE"
                            }
                        
                            Write-ColorOutput "Successfully created Stream Analytics input: $InputName" -ForegroundColor Green
                        }
                        catch {
                            Write-ColorOutput "Error creating Stream Analytics input '$InputName': $($_.Exception.Message)" -ForegroundColor Red
                            throw "Failed to create Stream Analytics input '$InputName': $($_.Exception.Message)"
                        }
                    }
                
                    "Blob" {
                        # Create storage account if it doesn't exist
                        $storageAccountName = Get-ValidStorageAccountName -BaseName "$($JobName.ToLower())storage" -ResourceGroup $ResourceGroup
                        $containerName = "input"
                    
                        # Check and create storage account
                        try {
                            $storageExists = az storage account show --name $storageAccountName --resource-group $ResourceGroup --output tsv 2>$null
                            if (-not $storageExists) {
                                az storage account create `
                                    --name $storageAccountName `
                                    --resource-group $ResourceGroup `
                                    --location $Location `
                                    --sku Standard_LRS
                            
                                if ($LASTEXITCODE -ne 0) {
                                    throw "Failed to create storage account '$storageAccountName'. Exit code: $LASTEXITCODE"
                                }
                            
                                Write-ColorOutput "Successfully created storage account: $storageAccountName" -ForegroundColor Green
                            }
                            else {
                                Write-ColorOutput "Storage account already exists: $storageAccountName" -ForegroundColor Green
                            }
                        }
                        catch {
                            Write-ColorOutput "Error with storage account operations: $($_.Exception.Message)" -ForegroundColor Red
                            throw "Failed to handle storage account '$storageAccountName': $($_.Exception.Message)"
                        }
                    
                        # Get storage account key
                        try {
                            $storageKey = az storage account keys list `
                                --account-name $storageAccountName `
                                --resource-group $ResourceGroup `
                                --query "[0].value" `
                                --output tsv
                        
                            if ($LASTEXITCODE -ne 0) {
                                throw "Failed to retrieve storage account key. Exit code: $LASTEXITCODE"
                            }
                        
                            if ([string]::IsNullOrWhiteSpace($storageKey)) {
                                throw "Storage account key is empty or null"
                            }
                        
                            Write-ColorOutput "Successfully retrieved storage account key" -ForegroundColor Green
                        }
                        catch {
                            Write-ColorOutput "Error retrieving storage account key: $($_.Exception.Message)" -ForegroundColor Red
                            throw "Failed to retrieve storage account key: $($_.Exception.Message)"
                        }
                    
                        # Check and create storage container
                        try {
                            $containerExists = az storage container show --name $containerName --account-name $storageAccountName --account-key $storageKey --output tsv 2>$null
                            if (-not $containerExists) {
                                az storage container create `
                                    --name $containerName `
                                    --account-name $storageAccountName `
                                    --account-key $storageKey
                            
                                if ($LASTEXITCODE -ne 0) {
                                    throw "Failed to create storage container '$containerName'. Exit code: $LASTEXITCODE"
                                }
                            
                                Write-ColorOutput "Successfully created storage container: $containerName" -ForegroundColor Green
                            }
                            else {
                                Write-ColorOutput "Storage container already exists: $containerName" -ForegroundColor Green
                            }
                        }
                        catch {
                            Write-ColorOutput "Error with storage container operations: $($_.Exception.Message)" -ForegroundColor Red
                            throw "Failed to handle storage container '$containerName': $($_.Exception.Message)"
                        }
                    
                        # Create Stream Analytics input
                        try {
                            az stream-analytics input create `
                                --name $InputName `
                                --job-name $JobName `
                                --resource-group $ResourceGroup `
                                --type Stream `
                                --datasource Microsoft.Storage/Blob `
                                --storage-accounts name=$storageAccountName account-key=$storageKey `
                                --container $containerName `
                                --path-pattern "{date}/{time}"
                        
                            if ($LASTEXITCODE -ne 0) {
                                throw "Failed to create Stream Analytics input '$InputName'. Exit code: $LASTEXITCODE"
                            }
                        
                            Write-ColorOutput "Successfully created Stream Analytics input: $InputName" -ForegroundColor Green
                        }
                        catch {
                            Write-ColorOutput "Error creating Stream Analytics input '$InputName': $($_.Exception.Message)" -ForegroundColor Red
                            throw "Failed to create Stream Analytics input '$InputName': $($_.Exception.Message)"
                        }
                    }
                
                    default {
                        throw "Unsupported input type: $InputType. Supported types are: EventHub, Blob"
                    }
                }
            
                Write-ColorOutput "Successfully created input source: $InputName" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "Input source already exists: $InputName" -ForegroundColor Green
            }
        }
        catch {
            Write-ColorOutput "Error with input source operations: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to handle input source '$InputName': $($_.Exception.Message)"
        }
        
        # Create output destination
        Write-ColorOutput "Creating output destination: $OutputName" -ForegroundColor Yellow
        try {
            # Check if output exists with proper error handling
            $outputExists = az stream-analytics output show --name $OutputName --job-name $JobName --resource-group $ResourceGroup --output tsv 2>$null
            
            if ($LASTEXITCODE -ne 0) {
                switch ($OutputType) {
                    "Blob" {
                        # Use existing storage account or create new one
                        $storageAccountName = Get-ValidStorageAccountName -BaseName "$($JobName.ToLower())outputstorage" -ResourceGroup $ResourceGroup
                        $containerName = "output"
                    
                        # Check and create storage account
                        try {
                            $storageExists = az storage account show --name $storageAccountName --resource-group $ResourceGroup --output tsv 2>$null
                            if (-not $storageExists) {
                                az storage account create `
                                    --name $storageAccountName `
                                    --resource-group $ResourceGroup `
                                    --location $Location `
                                    --sku Standard_LRS
                            
                                if ($LASTEXITCODE -ne 0) {
                                    throw "Failed to create storage account '$storageAccountName'. Exit code: $LASTEXITCODE"
                                }
                            
                                Write-ColorOutput "Successfully created storage account: $storageAccountName" -ForegroundColor Green
                            }
                            else {
                                Write-ColorOutput "Storage account already exists: $storageAccountName" -ForegroundColor Green
                            }
                        }
                        catch {
                            Write-ColorOutput "Error with storage account operations: $($_.Exception.Message)" -ForegroundColor Red
                            throw "Failed to handle storage account '$storageAccountName': $($_.Exception.Message)"
                        }
                    
                        # Get storage account key
                        try {
                            $storageKey = az storage account keys list `
                                --account-name $storageAccountName `
                                --resource-group $ResourceGroup `
                                --query "[0].value" `
                                --output tsv
                        
                            if ($LASTEXITCODE -ne 0) {
                                throw "Failed to retrieve storage account key. Exit code: $LASTEXITCODE"
                            }
                        
                            if ([string]::IsNullOrWhiteSpace($storageKey)) {
                                throw "Storage account key is empty or null"
                            }
                        
                            Write-ColorOutput "Successfully retrieved storage account key" -ForegroundColor Green
                        }
                        catch {
                            Write-ColorOutput "Error retrieving storage account key: $($_.Exception.Message)" -ForegroundColor Red
                            throw "Failed to retrieve storage account key: $($_.Exception.Message)"
                        }
                    
                        # Check and create storage container
                        try {
                            $containerExists = az storage container show --name $containerName --account-name $storageAccountName --account-key $storageKey --output tsv 2>$null
                            if (-not $containerExists) {
                                az storage container create `
                                    --name $containerName `
                                    --account-name $storageAccountName `
                                    --account-key $storageKey
                            
                                if ($LASTEXITCODE -ne 0) {
                                    throw "Failed to create storage container '$containerName'. Exit code: $LASTEXITCODE"
                                }
                            
                                Write-ColorOutput "Successfully created storage container: $containerName" -ForegroundColor Green
                            }
                            else {
                                Write-ColorOutput "Storage container already exists: $containerName" -ForegroundColor Green
                            }
                        }
                        catch {
                            Write-ColorOutput "Error with storage container operations: $($_.Exception.Message)" -ForegroundColor Red
                            throw "Failed to handle storage container '$containerName': $($_.Exception.Message)"
                        }
                    
                        # Create Stream Analytics output
                        try {
                            az stream-analytics output create `
                                --name $OutputName `
                                --job-name $JobName `
                                --resource-group $ResourceGroup `
                                --datasource Microsoft.Storage/Blob `
                                --storage-accounts name=$storageAccountName account-key=$storageKey `
                                --container $containerName `
                                --path-pattern "{date}/{time}" `
                                --serialization Microsoft.StreamAnalytics/JSON
                        
                            if ($LASTEXITCODE -ne 0) {
                                throw "Failed to create Stream Analytics output '$OutputName'. Exit code: $LASTEXITCODE"
                            }
                        
                            Write-ColorOutput "Successfully created Stream Analytics output: $OutputName" -ForegroundColor Green
                        }
                        catch {
                            Write-ColorOutput "Error creating Stream Analytics output '$OutputName': $($_.Exception.Message)" -ForegroundColor Red
                            throw "Failed to create Stream Analytics output '$OutputName': $($_.Exception.Message)"
                        }
                    }
                
                    default {
                        throw "Unsupported output type: $OutputType. Supported types are: Blob"
                    }
                }
            
                Write-ColorOutput "Successfully created output destination: $OutputName" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "Output destination already exists: $OutputName" -ForegroundColor Green
            }
        }
        catch {
            Write-ColorOutput "Error with output destination operations: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to handle output destination '$OutputName': $($_.Exception.Message)"
        }
        
        # Set query if provided
        if ($Query) {
            Write-ColorOutput "Setting Stream Analytics query..." -ForegroundColor Yellow
            try {
                az stream-analytics job update `
                    --name $JobName `
                    --resource-group $ResourceGroup `
                    --transformation-query $Query
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to update Stream Analytics job query"
                }
            }
            catch {
                Write-ColorOutput "Error updating Stream Analytics job query: $_" -ForegroundColor Red
                throw
            }
        }
        
        # Start job if requested
        if ($EnableJobStart) {
            Write-ColorOutput "Starting Stream Analytics job..." -ForegroundColor Yellow
            try {
                az stream-analytics job start `
                    --name $JobName `
                    --resource-group $ResourceGroup
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to start Stream Analytics job"
                }
                
                Write-ColorOutput "Stream Analytics job started successfully" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error starting Stream Analytics job: $_" -ForegroundColor Red
                throw
            }
        }
        
        # Get job details
        Write-ColorOutput "Getting job details..." -ForegroundColor Yellow
        try {
            $jobDetails = az stream-analytics job show `
                --name $JobName `
                --resource-group $ResourceGroup `
                --output json | ConvertFrom-Json
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve job details. Exit code: $LASTEXITCODE"
            }
            
            if (-not $jobDetails) {
                throw "Job details are empty or null"
            }
            
            Write-ColorOutput "Successfully retrieved job details" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving job details: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve job details for '$JobName': $($_.Exception.Message)"
        }
        
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
        
        # Security warning for sensitive data
        Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
        Write-ColorOutput "The returned object contains Stream Analytics job details." -ForegroundColor Yellow
        Write-ColorOutput "Please ensure this data is:" -ForegroundColor Yellow
        Write-ColorOutput "  • Not logged or written to files" -ForegroundColor Yellow
        Write-ColorOutput "  • Not committed to version control" -ForegroundColor Yellow
        Write-ColorOutput "  • Stored securely in production environments" -ForegroundColor Yellow
        Write-ColorOutput "  • Considered for Azure Key Vault integration" -ForegroundColor Yellow
        
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

function Get-ValidStorageAccountName {
    <#
    .SYNOPSIS
        Generates a valid Azure storage account name that meets Azure naming requirements.
    
    .DESCRIPTION
        Creates a storage account name that is 3-24 characters long, contains only
        lowercase letters and numbers, and is unique within the resource group.
    
    .PARAMETER BaseName
        The base name to use for the storage account.
    
    .PARAMETER ResourceGroup
        The resource group to check for existing storage accounts.
    
    .RETURNS
        A valid, unique storage account name.
    
    .EXAMPLE
        Get-ValidStorageAccountName -BaseName "mystorage" -ResourceGroup "my-rg"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseName,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup
    )
    
    # Clean the base name to meet Azure requirements
    $cleanBaseName = $BaseName -replace '[^a-z0-9]', '' -replace '^[0-9]', 'a'
    
    # Ensure the base name is not too long (leave room for random suffix)
    if ($cleanBaseName.Length -gt 15) {
        $cleanBaseName = $cleanBaseName.Substring(0, 15)
    }
    
    # Generate a unique storage account name with retry logic
    $maxAttempts = 10
    $attempt = 0
    $storageAccountName = $null
    
    do {
        $attempt++
        $randomSuffix = Get-Random -Minimum 100000 -Maximum 999999
        $storageAccountName = "$cleanBaseName$randomSuffix"
        
        # Ensure the name is within Azure limits (3-24 characters)
        if ($storageAccountName.Length -gt 24) {
            $storageAccountName = $storageAccountName.Substring(0, 24)
        }
        
        # Check if storage account exists
        $storageExists = az storage account show --name $storageAccountName --resource-group $ResourceGroup --output tsv 2>$null
        
        if ($storageExists) {
            Write-ColorOutput "Storage account $storageAccountName already exists, trying another name..." -ForegroundColor Yellow
            $storageAccountName = $null
        }
    } while (-not $storageAccountName -and $attempt -lt $maxAttempts)
    
    if (-not $storageAccountName) {
        throw "Failed to generate a unique storage account name after $maxAttempts attempts"
    }
    
    return $storageAccountName
} 