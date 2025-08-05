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
            # Note: Cloud-to-device messaging is enabled by default, but we can configure specific settings
            # such as max delivery count and TTL if needed in the future
        }
        
        # Create endpoints if requested
        if ($EnableEventHubEndpoint) {
            Write-ColorOutput "Creating Event Hub endpoint..." -ForegroundColor Gray
            $eventHubNamespace = "$($IoTHubName.ToLower())ehns$(Get-Random -Minimum 1000 -Maximum 9999)"
            $eventHubName = "$($IoTHubName.ToLower())eh$(Get-Random -Minimum 1000 -Maximum 9999)"
            
            # Create Event Hub namespace and hub
            az eventhubs namespace create `
                --name $eventHubNamespace `
                --resource-group $ResourceGroup `
                --location $Location `
                --sku Standard
            
            az eventhubs eventhub create `
                --name $eventHubName `
                --namespace-name $eventHubNamespace `
                --resource-group $ResourceGroup
            
            # Get subscription ID and connection string for Event Hub endpoint
            $subscriptionId = az account show --query id --output tsv
            $eventHubConnectionString = az eventhubs eventhub authorization-rule keys list `
                --eventhub-name $eventHubName `
                --namespace-name $eventHubNamespace `
                --name RootManageSharedAccessKey `
                --resource-group $ResourceGroup `
                --query primaryConnectionString `
                --output tsv
            
            # Add Event Hub endpoint to IoT Hub
            az iot hub routing-endpoint create `
                --hub-name $IoTHubName `
                --resource-group $ResourceGroup `
                --endpoint-name "eventhub-endpoint" `
                --endpoint-type eventhub `
                --endpoint-resource-group $ResourceGroup `
                --endpoint-subscription-id $subscriptionId `
                --endpoint-connection-string $eventHubConnectionString
        }
        
        if ($EnableServiceBusEndpoint) {
            Write-ColorOutput "Creating Service Bus endpoint..." -ForegroundColor Gray
            $serviceBusNamespace = "$($IoTHubName.ToLower())sbns$(Get-Random -Minimum 1000 -Maximum 9999)"
            $queueName = "$($IoTHubName.ToLower())queue$(Get-Random -Minimum 1000 -Maximum 9999)"
            
            # Create Service Bus namespace and queue
            az servicebus namespace create `
                --name $serviceBusNamespace `
                --resource-group $ResourceGroup `
                --location $Location `
                --sku Standard
            
            az servicebus queue create `
                --name $queueName `
                --namespace-name $serviceBusNamespace `
                --resource-group $ResourceGroup
            
            # Get subscription ID and connection string for Service Bus endpoint
            $subscriptionId = az account show --query id --output tsv
            $serviceBusConnectionString = az servicebus queue authorization-rule keys list `
                --queue-name $queueName `
                --namespace-name $serviceBusNamespace `
                --name RootManageSharedAccessKey `
                --resource-group $ResourceGroup `
                --query primaryConnectionString `
                --output tsv
            
            # Add Service Bus endpoint to IoT Hub
            az iot hub routing-endpoint create `
                --hub-name $IoTHubName `
                --resource-group $ResourceGroup `
                --endpoint-name "servicebus-endpoint" `
                --endpoint-type servicebusqueue `
                --endpoint-resource-group $ResourceGroup `
                --endpoint-subscription-id $subscriptionId `
                --endpoint-connection-string $serviceBusConnectionString
        }
        
        if ($EnableStorageEndpoint) {
            Write-ColorOutput "Creating Storage endpoint..." -ForegroundColor Gray
            $storageAccountName = "$($IoTHubName.ToLower())storage$(Get-Random -Minimum 1000 -Maximum 9999)"
            $containerName = "iothub-messages"
            
            # Create storage account and container
            az storage account create `
                --name $storageAccountName `
                --resource-group $ResourceGroup `
                --location $Location `
                --sku Standard_LRS
            
            $storageKey = az storage account keys list `
                --account-name $storageAccountName `
                --resource-group $ResourceGroup `
                --query "[0].value" `
                --output tsv
            
            az storage container create `
                --name $containerName `
                --account-name $storageAccountName `
                --account-key $storageKey
            
            # Get subscription ID and storage connection string
            $subscriptionId = az account show --query id --output tsv
            $storageConnectionString = az storage account show-connection-string `
                --name $storageAccountName `
                --resource-group $ResourceGroup `
                --query connectionString `
                --output tsv
            
            # Add Storage endpoint to IoT Hub
            az iot hub routing-endpoint create `
                --hub-name $IoTHubName `
                --resource-group $ResourceGroup `
                --endpoint-name "storage-endpoint" `
                --endpoint-type azurestoragecontainer `
                --endpoint-resource-group $ResourceGroup `
                --endpoint-subscription-id $subscriptionId `
                --endpoint-connection-string $storageConnectionString `
                --endpoint-container-name $containerName
        }
        
        # Create device provisioning service if requested
        if ($EnableDeviceProvisioning) {
            Write-ColorOutput "Creating Device Provisioning Service..." -ForegroundColor Yellow
            $dpsName = "$($IoTHubName.ToLower())dps$(Get-Random -Minimum 1000 -Maximum 9999)"
            
            az iot dps create `
                --name $dpsName `
                --resource-group $ResourceGroup `
                --location $Location `
                --sku S1
            
            # Link DPS to IoT Hub
            az iot dps linked-hub create `
                --dps-name $dpsName `
                --resource-group $ResourceGroup `
                --connection-string $connectionString `
                --location $Location
        }
        
        # Get IoT Hub details
        Write-ColorOutput "Getting IoT Hub details..." -ForegroundColor Yellow
        $iothubDetails = az iot hub show `
            --name $IoTHubName `
            --resource-group $ResourceGroup `
            --output json | ConvertFrom-Json
        
        # Get connection strings
        $connectionString = az iot hub connection-string show `
            --name $IoTHubName `
            --resource-group $ResourceGroup `
            --query connectionString `
            --output tsv
        
        $eventHubConnectionString = az iot hub connection-string show `
            --name $IoTHubName `
            --resource-group $ResourceGroup `
            --event-hub `
            --query connectionString `
            --output tsv
        
        # Get shared access policies
        $policies = az iot hub policy list `
            --name $IoTHubName `
            --resource-group $ResourceGroup `
            --output json | ConvertFrom-Json
        
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