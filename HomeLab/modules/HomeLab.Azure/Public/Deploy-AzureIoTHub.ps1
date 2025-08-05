function Deploy-AzureIoTHub {
    <#
    .SYNOPSIS
        Deploys Azure IoT Hub.
    
    .DESCRIPTION
        Deploys Azure IoT Hub with configurable parameters including
        pricing tiers, device management, and message routing.
    
    .PARAMETER ResourceGroup
        The resource group name where the IoT Hub will be deployed.
    
    .PARAMETER Location
        The Azure location for the deployment.
    
    .PARAMETER IoTHubName
        The name of the IoT Hub.
    
    .PARAMETER Sku
        The SKU for the IoT Hub (F1, S1, S2, S3).
    
    .PARAMETER UnitCount
        The number of units for the IoT Hub (1-200).
    
    .PARAMETER EnableDeviceProvisioning
        Whether to enable device provisioning service.
    
    .PARAMETER EnableFileUpload
        Whether to enable file upload notifications.
    
    .PARAMETER EnableCloudToDeviceMessages
        Whether to enable cloud-to-device messaging.
    
    .PARAMETER EnableDeviceTwin
        Whether to enable device twin functionality.
    
    .PARAMETER EnableMessageRouting
        Whether to enable message routing.
    
    .PARAMETER EnableEventHubEndpoint
        Whether to enable Event Hub endpoint.
    
    .PARAMETER EnableServiceBusEndpoint
        Whether to enable Service Bus endpoint.
    
    .PARAMETER EnableStorageEndpoint
        Whether to enable Storage endpoint.
    
    .EXAMPLE
        Deploy-AzureIoTHub -ResourceGroup "my-rg" -Location "southafricanorth" -IoTHubName "my-iothub"
    
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
        [string]$IoTHubName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("F1", "S1", "S2", "S3")]
        [string]$Sku = "S1",
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 200)]
        [int]$UnitCount = 1,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableDeviceProvisioning = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableFileUpload = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableCloudToDeviceMessages = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableDeviceTwin = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableMessageRouting = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableEventHubEndpoint = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableServiceBusEndpoint = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableStorageEndpoint = $false
    )
    
    try {
        Write-ColorOutput "Starting Azure IoT Hub deployment..." -ForegroundColor Cyan
        
        # Check if resource group exists
        $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
        if ($rgExists -ne "true") {
            Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
            az group create --name $ResourceGroup --location $Location
        }
        
        # Create IoT Hub
        Write-ColorOutput "Creating IoT Hub: $IoTHubName" -ForegroundColor Yellow
        $iothubExists = az iot hub show --name $IoTHubName --resource-group $ResourceGroup --output tsv 2>$null
        if (-not $iothubExists) {
            az iot hub create `
                --name $IoTHubName `
                --resource-group $ResourceGroup `
                --location $Location `
                --sku $Sku `
                --unit $UnitCount
        }
        
        # Configure IoT Hub features
        Write-ColorOutput "Configuring IoT Hub features..." -ForegroundColor Yellow
        
        # Note: File upload, cloud-to-device messaging, device twin, and message routing are enabled by default
        # in Azure IoT Hub and do not require explicit configuration via az iot hub update commands.
        # These features are automatically available when the IoT Hub is created.
        
        # Configure cloud-to-device messaging settings if requested
        if ($EnableCloudToDeviceMessages) {
            Write-ColorOutput "Configuring cloud-to-device messaging settings..." -ForegroundColor Gray
            # Note: Cloud-to-device messaging is enabled by default in IoT Hub
            # Additional configuration can be done through the Azure portal or REST API if needed
            Write-ColorOutput "Cloud-to-device messaging is enabled by default in IoT Hub" -ForegroundColor Green
        }
        
        # Create endpoints if requested
        if ($EnableEventHubEndpoint) {
            Write-ColorOutput "Creating Event Hub endpoint..." -ForegroundColor Gray
            $eventHubNamespace = "$($IoTHubName.ToLower())ehns$(Get-Random -Minimum 1000 -Maximum 9999)"
            $eventHubName = "$($IoTHubName.ToLower())eh$(Get-Random -Minimum 1000 -Maximum 9999)"
            
            # Create Event Hub namespace and hub
            try {
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
            catch {
                Write-ColorOutput "Error creating Event Hub namespace '$eventHubNamespace': $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Event Hub namespace '$eventHubNamespace': $($_.Exception.Message)"
            }
            
            try {
                az eventhubs eventhub create `
                    --name $eventHubName `
                    --namespace-name $eventHubNamespace `
                    --resource-group $ResourceGroup
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Event Hub '$eventHubName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Event Hub: $eventHubName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Event Hub '$eventHubName': $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Event Hub '$eventHubName': $($_.Exception.Message)"
            }
            
            # Get subscription ID and connection string for Event Hub endpoint
            try {
                $subscriptionId = az account show --query id --output tsv
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to retrieve subscription ID. Exit code: $LASTEXITCODE"
                }
                
                if ([string]::IsNullOrWhiteSpace($subscriptionId)) {
                    throw "Subscription ID is empty or null. Please check if you're authenticated to Azure."
                }
                
                Write-ColorOutput "Successfully retrieved subscription ID" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error retrieving subscription ID: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to retrieve subscription ID: $($_.Exception.Message)"
            }
            
            try {
                $eventHubConnectionString = az eventhubs eventhub authorization-rule keys list `
                    --eventhub-name $eventHubName `
                    --namespace-name $eventHubNamespace `
                    --name RootManageSharedAccessKey `
                    --resource-group $ResourceGroup `
                    --query primaryConnectionString `
                    --output tsv
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to retrieve Event Hub connection string. Exit code: $LASTEXITCODE"
                }
                
                if ([string]::IsNullOrWhiteSpace($eventHubConnectionString)) {
                    throw "Event Hub connection string is empty or null. Please check if the Event Hub was created successfully."
                }
                
                Write-ColorOutput "Successfully retrieved Event Hub connection string" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error retrieving Event Hub connection string: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to retrieve Event Hub connection string: $($_.Exception.Message)"
            }
            
            # Add Event Hub endpoint to IoT Hub
            try {
                az iot hub routing-endpoint create `
                    --hub-name $IoTHubName `
                    --resource-group $ResourceGroup `
                    --endpoint-name "eventhub-endpoint" `
                    --endpoint-type eventhub `
                    --endpoint-resource-group $ResourceGroup `
                    --endpoint-subscription-id $subscriptionId `
                    --endpoint-connection-string $eventHubConnectionString
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Event Hub routing endpoint. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Event Hub routing endpoint" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Event Hub routing endpoint: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Event Hub routing endpoint: $($_.Exception.Message)"
            }
        }
        
        if ($EnableServiceBusEndpoint) {
            Write-ColorOutput "Creating Service Bus endpoint..." -ForegroundColor Gray
            $serviceBusNamespace = "$($IoTHubName.ToLower())sbns$(Get-Random -Minimum 1000 -Maximum 9999)"
            $queueName = "$($IoTHubName.ToLower())queue$(Get-Random -Minimum 1000 -Maximum 9999)"
            
            # Create Service Bus namespace and queue
            try {
                az servicebus namespace create `
                    --name $serviceBusNamespace `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --sku Standard
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Service Bus namespace '$serviceBusNamespace'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Service Bus namespace: $serviceBusNamespace" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Service Bus namespace '$serviceBusNamespace': $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Service Bus namespace '$serviceBusNamespace': $($_.Exception.Message)"
            }
            
            try {
                az servicebus queue create `
                    --name $queueName `
                    --namespace-name $serviceBusNamespace `
                    --resource-group $ResourceGroup
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Service Bus queue '$queueName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Service Bus queue: $queueName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Service Bus queue '$queueName': $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Service Bus queue '$queueName': $($_.Exception.Message)"
            }
            
            # Get subscription ID and connection string for Service Bus endpoint
            try {
                $subscriptionId = az account show --query id --output tsv
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to retrieve subscription ID. Exit code: $LASTEXITCODE"
                }
                
                if ([string]::IsNullOrWhiteSpace($subscriptionId)) {
                    throw "Subscription ID is empty or null. Please check if you're authenticated to Azure."
                }
                
                Write-ColorOutput "Successfully retrieved subscription ID" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error retrieving subscription ID: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to retrieve subscription ID: $($_.Exception.Message)"
            }
            
            try {
                $serviceBusConnectionString = az servicebus queue authorization-rule keys list `
                    --queue-name $queueName `
                    --namespace-name $serviceBusNamespace `
                    --name RootManageSharedAccessKey `
                    --resource-group $ResourceGroup `
                    --query primaryConnectionString `
                    --output tsv
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to retrieve Service Bus connection string. Exit code: $LASTEXITCODE"
                }
                
                if ([string]::IsNullOrWhiteSpace($serviceBusConnectionString)) {
                    throw "Service Bus connection string is empty or null. Please check if the Service Bus was created successfully."
                }
                
                Write-ColorOutput "Successfully retrieved Service Bus connection string" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error retrieving Service Bus connection string: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to retrieve Service Bus connection string: $($_.Exception.Message)"
            }
            
            # Add Service Bus endpoint to IoT Hub
            try {
                az iot hub routing-endpoint create `
                    --hub-name $IoTHubName `
                    --resource-group $ResourceGroup `
                    --endpoint-name "servicebus-endpoint" `
                    --endpoint-type servicebusqueue `
                    --endpoint-resource-group $ResourceGroup `
                    --endpoint-subscription-id $subscriptionId `
                    --endpoint-connection-string $serviceBusConnectionString
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Service Bus routing endpoint. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Service Bus routing endpoint" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Service Bus routing endpoint: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Service Bus routing endpoint: $($_.Exception.Message)"
            }
        }
        
        if ($EnableStorageEndpoint) {
            Write-ColorOutput "Creating Storage endpoint..." -ForegroundColor Gray
            $storageAccountName = "$($IoTHubName.ToLower())storage$(Get-Random -Minimum 1000 -Maximum 9999)"
            $containerName = "iothub-messages"
            
            # Create storage account and container
            try {
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
            catch {
                Write-ColorOutput "Error creating storage account '$storageAccountName': $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create storage account '$storageAccountName': $($_.Exception.Message)"
            }
            
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
                    throw "Storage account key is empty or null. Please check if the storage account was created successfully."
                }
                
                Write-ColorOutput "Successfully retrieved storage account key" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error retrieving storage account key: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to retrieve storage account key: $($_.Exception.Message)"
            }
            
            try {
                az storage container create `
                    --name $containerName `
                    --account-name $storageAccountName `
                    --account-key $storageKey
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create storage container '$containerName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created storage container: $containerName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating storage container '$containerName': $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create storage container '$containerName': $($_.Exception.Message)"
            }
            
            # Get subscription ID and storage connection string
            try {
                $subscriptionId = az account show --query id --output tsv
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to retrieve subscription ID. Exit code: $LASTEXITCODE"
                }
                
                if ([string]::IsNullOrWhiteSpace($subscriptionId)) {
                    throw "Subscription ID is empty or null. Please check if you're authenticated to Azure."
                }
                
                Write-ColorOutput "Successfully retrieved subscription ID" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error retrieving subscription ID: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to retrieve subscription ID: $($_.Exception.Message)"
            }
            
            try {
                $storageConnectionString = az storage account show-connection-string `
                    --name $storageAccountName `
                    --resource-group $ResourceGroup `
                    --query connectionString `
                    --output tsv
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to retrieve storage connection string. Exit code: $LASTEXITCODE"
                }
                
                if ([string]::IsNullOrWhiteSpace($storageConnectionString)) {
                    throw "Storage connection string is empty or null. Please check if the storage account was created successfully."
                }
                
                Write-ColorOutput "Successfully retrieved storage connection string" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error retrieving storage connection string: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to retrieve storage connection string: $($_.Exception.Message)"
            }
            
            # Add Storage endpoint to IoT Hub
            try {
                az iot hub routing-endpoint create `
                    --hub-name $IoTHubName `
                    --resource-group $ResourceGroup `
                    --endpoint-name "storage-endpoint" `
                    --endpoint-type azurestoragecontainer `
                    --endpoint-resource-group $ResourceGroup `
                    --endpoint-subscription-id $subscriptionId `
                    --endpoint-connection-string $storageConnectionString `
                    --endpoint-container-name $containerName
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Storage routing endpoint. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Storage routing endpoint" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Storage routing endpoint: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Storage routing endpoint: $($_.Exception.Message)"
            }
        }
        
        # Create device provisioning service if requested
        if ($EnableDeviceProvisioning) {
            Write-ColorOutput "Creating Device Provisioning Service..." -ForegroundColor Yellow
            $dpsName = "$($IoTHubName.ToLower())dps$(Get-Random -Minimum 1000 -Maximum 9999)"
            
            try {
                az iot dps create `
                    --name $dpsName `
                    --resource-group $ResourceGroup `
                    --location $Location `
                    --sku S1
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create Device Provisioning Service '$dpsName'. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully created Device Provisioning Service: $dpsName" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error creating Device Provisioning Service '$dpsName': $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to create Device Provisioning Service '$dpsName': $($_.Exception.Message)"
            }
            
            # Link DPS to IoT Hub
            try {
                az iot dps linked-hub create `
                    --dps-name $dpsName `
                    --resource-group $ResourceGroup `
                    --connection-string $connectionString `
                    --location $Location
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to link DPS to IoT Hub. Exit code: $LASTEXITCODE"
                }
                
                Write-ColorOutput "Successfully linked DPS to IoT Hub" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error linking DPS to IoT Hub: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to link DPS to IoT Hub: $($_.Exception.Message)"
            }
        }
        
        # Get IoT Hub details
        Write-ColorOutput "Getting IoT Hub details..." -ForegroundColor Yellow
        try {
            $iothubDetails = az iot hub show `
                --name $IoTHubName `
                --resource-group $ResourceGroup `
                --output json | ConvertFrom-Json
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve IoT Hub details. Exit code: $LASTEXITCODE"
            }
            
            Write-ColorOutput "Successfully retrieved IoT Hub details" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving IoT Hub details: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve IoT Hub details: $($_.Exception.Message)"
        }
        
        # Get connection strings
        try {
            $connectionString = az iot hub connection-string show `
                --name $IoTHubName `
                --resource-group $ResourceGroup `
                --query connectionString `
                --output tsv
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve IoT Hub connection string. Exit code: $LASTEXITCODE"
            }
            
            if ([string]::IsNullOrWhiteSpace($connectionString)) {
                throw "IoT Hub connection string is empty or null. Please check if the IoT Hub was created successfully."
            }
            
            Write-ColorOutput "Successfully retrieved IoT Hub connection string" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving IoT Hub connection string: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve IoT Hub connection string: $($_.Exception.Message)"
        }
        
        try {
            $eventHubConnectionString = az iot hub connection-string show `
                --name $IoTHubName `
                --resource-group $ResourceGroup `
                --event-hub `
                --query connectionString `
                --output tsv
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve Event Hub connection string. Exit code: $LASTEXITCODE"
            }
            
            if ([string]::IsNullOrWhiteSpace($eventHubConnectionString)) {
                throw "Event Hub connection string is empty or null. Please check if the IoT Hub was created successfully."
            }
            
            Write-ColorOutput "Successfully retrieved Event Hub connection string" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving Event Hub connection string: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve Event Hub connection string: $($_.Exception.Message)"
        }
        
        # Get shared access policies
        try {
            $policies = az iot hub policy list `
                --name $IoTHubName `
                --resource-group $ResourceGroup `
                --output json | ConvertFrom-Json
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve IoT Hub policies. Exit code: $LASTEXITCODE"
            }
            
            Write-ColorOutput "Successfully retrieved IoT Hub policies" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving IoT Hub policies: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve IoT Hub policies: $($_.Exception.Message)"
        }
        
        # Display deployment summary
        Write-ColorOutput "`nAzure IoT Hub deployment completed successfully!" -ForegroundColor Green
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "IoT Hub Name: $IoTHubName" -ForegroundColor Gray
        Write-ColorOutput "SKU: $Sku" -ForegroundColor Gray
        Write-ColorOutput "Unit Count: $UnitCount" -ForegroundColor Gray
        Write-ColorOutput "Location: $Location" -ForegroundColor Gray
        Write-ColorOutput "Connection String: $connectionString" -ForegroundColor Gray
        Write-ColorOutput "Event Hub Connection String: $eventHubConnectionString" -ForegroundColor Gray
        Write-ColorOutput "IoT Hub ID: $($iothubDetails.id)" -ForegroundColor Gray
        
        if ($EnableDeviceProvisioning) {
            Write-ColorOutput "Device Provisioning Service: $dpsName" -ForegroundColor Gray
        }
        
        # Security warning for sensitive data
        Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
        Write-ColorOutput "The returned object contains sensitive IoT Hub connection strings." -ForegroundColor Yellow
        Write-ColorOutput "Please ensure this data is:" -ForegroundColor Yellow
        Write-ColorOutput "  • Not logged or written to files" -ForegroundColor Yellow
        Write-ColorOutput "  • Not committed to version control" -ForegroundColor Yellow
        Write-ColorOutput "  • Stored securely in production environments" -ForegroundColor Yellow
        Write-ColorOutput "  • Considered for Azure Key Vault integration" -ForegroundColor Yellow
        
        # Return deployment info
        return @{
            ResourceGroup             = $ResourceGroup
            IoTHubName                = $IoTHubName
            Sku                       = $Sku
            UnitCount                 = $UnitCount
            Location                  = $Location
            ConnectionString          = $connectionString
            EventHubConnectionString  = $eventHubConnectionString
            IoTHubId                  = $iothubDetails.id
            DeviceProvisioningService = if ($EnableDeviceProvisioning) { $dpsName } else { $null }
            IoTHubDetails             = $iothubDetails
            Policies                  = $policies
        }
    }
    catch {
        Write-ColorOutput "Error deploying Azure IoT Hub: $_" -ForegroundColor Red
        throw
    }
} 