function Show-WebsiteMenu {
    <#
    .SYNOPSIS
        Displays the layered website deployment menu.
    
    .DESCRIPTION
        This function displays a layered menu for website deployment options,
        organized by complexity and deployment type.
    
    .EXAMPLE
        Show-WebsiteMenu
    #>
    [CmdletBinding()]
    param()
    
    do {
        Clear-Host
        
        # Display the layered menu header
        Write-ColorOutput @"
        
╔══════════════════════════════════════════════════════════════════╗
║                 WEBSITE DEPLOYMENT - LAYERED MENU                ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
        
        Write-ColorOutput ""
        Write-ColorOutput "  Choose a deployment layer:" -ForegroundColor White
        Write-ColorOutput ""
        Write-ColorOutput "  [1] Layer 1: Basic Web Hosting" -ForegroundColor Green
        Write-ColorOutput "      Static sites, App Service, Vercel, Netlify, AWS S3, GCP" -ForegroundColor Gray
        Write-ColorOutput ""
        Write-ColorOutput "  [2] Layer 2: Container Orchestration & Serverless" -ForegroundColor Yellow
        Write-ColorOutput "      Container Apps, Functions, ECS, Lambda, Kubernetes" -ForegroundColor Gray
        Write-ColorOutput ""
        Write-ColorOutput "  [3] Layer 3: Database & Storage Services" -ForegroundColor Blue
        Write-ColorOutput "      Coming Soon: SQL, NoSQL, Blob Storage, CDN" -ForegroundColor Gray
        Write-ColorOutput ""
        Write-ColorOutput "  [4] Layer 4: AI/ML & Analytics Services" -ForegroundColor Magenta
        Write-ColorOutput "      Coming Soon: Cognitive Services, ML Studio, Analytics" -ForegroundColor Gray
        Write-ColorOutput ""
        Write-ColorOutput "  [5] Layer 5: IoT & Edge Computing" -ForegroundColor Cyan
        Write-ColorOutput "      Coming Soon: IoT Hub, Edge Modules, Stream Analytics" -ForegroundColor Gray
        Write-ColorOutput ""
        Write-ColorOutput "  [6] Multi-Cloud & Hybrid Deployments" -ForegroundColor White
        Write-ColorOutput "      Coming Soon: Cross-platform deployments" -ForegroundColor Gray
        Write-ColorOutput ""
        Write-ColorOutput "  [0] Return to Main Menu" -ForegroundColor Red
        Write-ColorOutput ""
        
        $choice = Read-Host "Select a layer (0-6)"
        
        switch ($choice) {
            "1" { Show-Layer1BasicHosting }
            "2" { Show-Layer2ContainerServerless }
            "3" { Show-Layer3DatabaseStorage }
            "4" { Show-Layer4AIMLAnalytics }
            "5" { Show-Layer5IoTEdgeComputing }
            "6" { Show-MultiCloudHybrid }
            "0" { return }
            default {
                Write-ColorOutput "Invalid choice. Please select 0-6." -ForegroundColor Red
                Start-Sleep 2
            }
        }
    } while ($true)
}

function Show-Layer1BasicHosting {
    <#
    .SYNOPSIS
        Displays Layer 1: Basic Web Hosting options.
    #>
    [CmdletBinding()]
    param()
    
    $menuItems = @{
        "1"  = "Browse and Select Project"
        "2"  = "Deploy Static Website (Azure)"
        "3"  = "Deploy App Service Website (Azure)"
        "4"  = "Deploy to Vercel (Next.js, React, Vue)"
        "5"  = "Deploy to Netlify (Static sites, JAMstack)"
        "6"  = "Deploy to AWS (S3 + CloudFront, Amplify)"
        "7"  = "Deploy to Google Cloud (Cloud Run, App Engine)"
        "8"  = "Auto-Detect and Deploy Website"
        "9"  = "Configure Custom Domain"
        "10" = "Add GitHub Workflows"
        "11" = "Show Deployment Type Info"
        "12" = "List Deployed Websites"
    }
    
    do {
        Clear-Host
        
        Write-ColorOutput @"
        
╔══════════════════════════════════════════════════════════════════╗
║                LAYER 1: BASIC WEB HOSTING                        ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Green
        
        Write-ColorOutput ""
        Write-ColorOutput "  Perfect for static sites, simple web apps, and basic hosting needs." -ForegroundColor Gray
        Write-ColorOutput ""
        
        try {
            $result = Show-Menu -Title "Basic Web Hosting Options" -MenuItems $menuItems `
                -ExitOption "0" -ExitText "Return to Layer Selection" `
                -ValidateInput
        }
        catch {
            Write-ColorOutput "ERROR in Show-Menu call: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
        
        if ($result.IsExit -eq $true) {
            break
        }
        
        # Handle the menu selection
        switch ($result.Choice) {
            "1" { Invoke-WebsiteHandler -Command "Browse-Project" }
            "2" { Invoke-WebsiteHandler -Command "Deploy-StaticWebsite" }
            "3" { Invoke-WebsiteHandler -Command "Deploy-AppServiceWebsite" }
            "4" { Invoke-WebsiteHandler -Command "Deploy-VercelWebsite" }
            "5" { Invoke-WebsiteHandler -Command "Deploy-NetlifyWebsite" }
            "6" { Invoke-WebsiteHandler -Command "Deploy-AWSWebsite" }
            "7" { Invoke-WebsiteHandler -Command "Deploy-GCPWebsite" }
            "8" { Invoke-WebsiteHandler -Command "Deploy-AutoDetectWebsite" }
            "9" { Invoke-WebsiteHandler -Command "Configure-WebsiteCustomDomain" }
            "10" { Invoke-WebsiteHandler -Command "Add-GitHubWorkflowsMenu" }
            "11" { Invoke-WebsiteHandler -Command "Show-DeploymentTypeInfoMenu" }
            "12" { Invoke-WebsiteHandler -Command "List-DeployedWebsites" }
            default {
                Write-ColorOutput "Invalid selection: $($result.Choice)" -ForegroundColor Red
                Start-Sleep 2
            }
        }
    } while ($true)
}

function Show-Layer2ContainerServerless {
    <#
    .SYNOPSIS
        Displays Layer 2: Container Orchestration & Serverless options.
    #>
    [CmdletBinding()]
    param()
    
    $menuItems = @{
        "1"  = "Browse and Select Project"
        "2"  = "Deploy to Azure Container Apps (Serverless Containers)"
        "3"  = "Deploy to Azure Functions (Serverless Functions)"
        "4"  = "Deploy to AWS ECS Fargate (Serverless Containers)"
        "5"  = "Deploy to AWS Lambda (Serverless Functions)"
        "6"  = "Deploy to Google Cloud Functions (Serverless Functions)"
        "7"  = "Deploy to Azure Kubernetes Service (AKS)"
        "8"  = "Deploy to AWS EKS (Kubernetes)"
        "9"  = "Deploy to Google Kubernetes Engine (GKE)"
        "10" = "Auto-Detect and Deploy Container/Serverless"
        "11" = "Configure Custom Domain"
        "12" = "Add GitHub Workflows"
        "13" = "Show Deployment Type Info"
        "14" = "List Deployed Applications"
    }
    
    do {
        Clear-Host
        
        Write-ColorOutput @"
        
╔══════════════════════════════════════════════════════════════════╗
║           LAYER 2: CONTAINER ORCHESTRATION & SERVERLESS          ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Yellow
        
        Write-ColorOutput ""
        Write-ColorOutput "  Advanced deployment options for microservices, containers, and serverless applications." -ForegroundColor Gray
        Write-ColorOutput ""
        
        try {
            $result = Show-Menu -Title "Container & Serverless Options" -MenuItems $menuItems `
                -ExitOption "0" -ExitText "Return to Layer Selection" `
                -ValidateInput
        }
        catch {
            Write-ColorOutput "ERROR in Show-Menu call: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
        
        if ($result.IsExit -eq $true) {
            break
        }
        
        # Handle the menu selection
        switch ($result.Choice) {
            "1" { Invoke-WebsiteHandler -Command "Browse-Project" }
            "2" { Invoke-WebsiteHandler -Command "Deploy-ContainerAppsWebsite" }
            "3" { Invoke-WebsiteHandler -Command "Deploy-FunctionsWebsite" }
            "4" { Invoke-WebsiteHandler -Command "Deploy-ECSWebsite" }
            "5" { Invoke-WebsiteHandler -Command "Deploy-LambdaWebsite" }
            "6" { Invoke-WebsiteHandler -Command "Deploy-CloudFunctionsWebsite" }
            "7" { Invoke-WebsiteHandler -Command "Deploy-AKSWebsite" }
            "8" { Invoke-WebsiteHandler -Command "Deploy-EKSWebsite" }
            "9" { Invoke-WebsiteHandler -Command "Deploy-GKEWebsite" }
            "10" { Invoke-WebsiteHandler -Command "Deploy-AutoDetectContainerServerless" }
            "11" { Invoke-WebsiteHandler -Command "Configure-WebsiteCustomDomain" }
            "12" { Invoke-WebsiteHandler -Command "Add-GitHubWorkflowsMenu" }
            "13" { Invoke-WebsiteHandler -Command "Show-DeploymentTypeInfoMenu" }
            "14" { Invoke-WebsiteHandler -Command "List-DeployedApplications" }
            default {
                Write-ColorOutput "Invalid selection: $($result.Choice)" -ForegroundColor Red
                Start-Sleep 2
            }
        }
    } while ($true)
}

function Show-Layer3DatabaseStorage {
    <#
    .SYNOPSIS
        Displays Layer 3: Database & Storage Services.
    #>
    [CmdletBinding()]
    param()
    
    $menuItems = @{
        "1"  = "Browse and Select Project"
        "2"  = "Deploy Azure SQL Database"
        "3"  = "Deploy Azure Cosmos DB"
        "4"  = "Deploy Azure Blob Storage"
        "5"  = "Deploy Azure CDN"
        "6"  = "Deploy AWS RDS"
        "7"  = "Deploy AWS DynamoDB"
        "8"  = "Deploy AWS S3 Storage"
        "9"  = "Deploy Google Cloud SQL"
        "10" = "Deploy Google Cloud Storage"
        "11" = "Auto-Detect and Deploy Database/Storage"
        "12" = "Configure Database Connections"
        "13" = "Show Database/Storage Type Info"
        "14" = "List Deployed Databases/Storage"
    }
    
    do {
        Clear-Host
        
        Write-ColorOutput @"
        
╔══════════════════════════════════════════════════════════════════╗
║              LAYER 3: DATABASE & STORAGE SERVICES                ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Blue
        
        Write-ColorOutput ""
        Write-ColorOutput "  Database and storage services for your applications." -ForegroundColor Gray
        Write-ColorOutput "  Deploy SQL, NoSQL, blob storage, and CDN services." -ForegroundColor Gray
        Write-ColorOutput ""
        
        try {
            $result = Show-Menu -Title "Database & Storage Options" -MenuItems $menuItems `
                -ExitOption "0" -ExitText "Return to Layer Selection" `
                -ValidateInput
        }
        catch {
            Write-ColorOutput "ERROR in Show-Menu call: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
        
        if ($result.IsExit -eq $true) {
            break
        }
        
        # Handle the menu selection
        switch ($result.Choice) {
            "1" { Invoke-DatabaseStorageHandler -Command "Browse-Project" }
            "2" { Invoke-DatabaseStorageHandler -Command "Deploy-AzureSQLDatabase" }
            "3" { Invoke-DatabaseStorageHandler -Command "Deploy-AzureCosmosDB" }
            "4" { Invoke-DatabaseStorageHandler -Command "Deploy-AzureBlobStorage" }
            "5" { Invoke-DatabaseStorageHandler -Command "Deploy-AzureCDN" }
            "6" { Invoke-DatabaseStorageHandler -Command "Deploy-AWSRDS" }
            "7" { Invoke-DatabaseStorageHandler -Command "Deploy-AWSDynamoDB" }
            "8" { Invoke-DatabaseStorageHandler -Command "Deploy-AWSS3Storage" }
            "9" { Invoke-DatabaseStorageHandler -Command "Deploy-GCPCloudSQL" }
            "10" { Invoke-DatabaseStorageHandler -Command "Deploy-GCPCloudStorage" }
            "11" { Invoke-DatabaseStorageHandler -Command "Deploy-AutoDetectDatabaseStorage" }
            "12" { Invoke-DatabaseStorageHandler -Command "Configure-DatabaseConnections" }
            "13" { Invoke-DatabaseStorageHandler -Command "Show-DatabaseStorageTypeInfo" }
            "14" { Invoke-DatabaseStorageHandler -Command "List-DeployedDatabasesStorage" }
            default {
                Write-ColorOutput "Invalid selection: $($result.Choice)" -ForegroundColor Red
                Start-Sleep 2
            }
        }
    } while ($true)
}

function Show-Layer4AIMLAnalytics {
    <#
    .SYNOPSIS
        Displays Layer 4: AI/ML & Analytics Services.
    #>
    [CmdletBinding()]
    param()
    
    $menuItems = @{
        "1"  = "Browse and Select Project"
        "2"  = "Deploy Azure Cognitive Services"
        "3"  = "Deploy Azure Machine Learning Studio"
        "4"  = "Deploy Azure Stream Analytics"
        "5"  = "Deploy Azure Data Factory"
        "6"  = "Deploy Azure Synapse Analytics"
        "7"  = "Deploy AWS SageMaker"
        "8"  = "Deploy AWS Comprehend"
        "9"  = "Deploy AWS Rekognition"
        "10" = "Deploy Google Cloud AI Platform"
        "11" = "Deploy Google Cloud Vision API"
        "12" = "Auto-Detect and Deploy AI/ML Services"
        "13" = "Configure AI/ML Model Endpoints"
        "14" = "Show AI/ML Service Type Info"
        "15" = "List Deployed AI/ML Services"
    }
    
    do {
        Clear-Host
        
        Write-ColorOutput @"
        
╔══════════════════════════════════════════════════════════════════╗
║              LAYER 4: AI/ML & ANALYTICS SERVICES                 ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Magenta
        
        Write-ColorOutput ""
        Write-ColorOutput "  AI/ML and analytics services for intelligent applications." -ForegroundColor Gray
        Write-ColorOutput "  Deploy cognitive services, machine learning, and data analytics." -ForegroundColor Gray
        Write-ColorOutput ""
        
        try {
            $result = Show-Menu -Title "AI/ML & Analytics Options" -MenuItems $menuItems `
                -ExitOption "0" -ExitText "Return to Layer Selection" `
                -ValidateInput
        }
        catch {
            Write-ColorOutput "ERROR in Show-Menu call: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
        
        if ($result.IsExit -eq $true) {
            break
        }
        
        # Handle the menu selection
        switch ($result.Choice) {
            "1" { Invoke-AIMLAnalyticsHandler -Command "Browse-Project" }
            "2" { Invoke-AIMLAnalyticsHandler -Command "Deploy-AzureCognitiveServices" }
            "3" { Invoke-AIMLAnalyticsHandler -Command "Deploy-AzureMachineLearningStudio" }
            "4" { Invoke-AIMLAnalyticsHandler -Command "Deploy-AzureStreamAnalytics" }
            "5" { Invoke-AIMLAnalyticsHandler -Command "Deploy-AzureDataFactory" }
            "6" { Invoke-AIMLAnalyticsHandler -Command "Deploy-AzureSynapseAnalytics" }
            "7" { Invoke-AIMLAnalyticsHandler -Command "Deploy-AWSSageMaker" }
            "8" { Invoke-AIMLAnalyticsHandler -Command "Deploy-AWSComprehend" }
            "9" { Invoke-AIMLAnalyticsHandler -Command "Deploy-AWSRekognition" }
            "10" { Invoke-AIMLAnalyticsHandler -Command "Deploy-GCPAIPlatform" }
            "11" { Invoke-AIMLAnalyticsHandler -Command "Deploy-GCPVisionAPI" }
            "12" { Invoke-AIMLAnalyticsHandler -Command "Deploy-AutoDetectAIMLServices" }
            "13" { Invoke-AIMLAnalyticsHandler -Command "Configure-AIMLModelEndpoints" }
            "14" { Invoke-AIMLAnalyticsHandler -Command "Show-AIMLServiceTypeInfo" }
            "15" { Invoke-AIMLAnalyticsHandler -Command "List-DeployedAIMLServices" }
            default {
                Write-ColorOutput "Invalid selection: $($result.Choice)" -ForegroundColor Red
                Start-Sleep 2
            }
        }
    } while ($true)
}

function Show-Layer5IoTEdgeComputing {
    <#
    .SYNOPSIS
        Displays Layer 5: IoT & Edge Computing Services.
    #>
    [CmdletBinding()]
    param()
    
    $menuItems = @{
        "1"  = "Browse and Select Project"
        "2"  = "Deploy Azure IoT Hub"
        "3"  = "Deploy Azure IoT Edge Runtime"
        "4"  = "Deploy Azure IoT Central"
        "5"  = "Deploy Azure Digital Twins"
        "6"  = "Deploy Azure Sphere"
        "7"  = "Deploy AWS IoT Core"
        "8"  = "Deploy AWS Greengrass"
        "9"  = "Deploy Google Cloud IoT Core"
        "10" = "Deploy Edge Computing Cluster"
        "11" = "Auto-Detect and Deploy IoT Services"
        "12" = "Configure IoT Device Management"
        "13" = "Show IoT & Edge Service Type Info"
        "14" = "List Deployed IoT & Edge Services"
    }
    
    do {
        Clear-Host
        
        Write-ColorOutput @"
        
╔══════════════════════════════════════════════════════════════════╗
║            LAYER 5: IOT & EDGE COMPUTING SERVICES                ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor DarkYellow
        
        Write-ColorOutput ""
        Write-ColorOutput "  IoT and edge computing services for connected devices." -ForegroundColor Gray
        Write-ColorOutput "  Deploy IoT hubs, edge runtimes, and device management." -ForegroundColor Gray
        Write-ColorOutput ""
        
        try {
            $result = Show-Menu -Title "IoT & Edge Computing Options" -MenuItems $menuItems `
                -ExitOption "0" -ExitText "Return to Layer Selection" `
                -ValidateInput
        }
        catch {
            Write-ColorOutput "ERROR in Show-Menu call: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
        
        if ($result.IsExit -eq $true) {
            break
        }
        
        # Handle the menu selection
        switch ($result.Choice) {
            "1" { Invoke-IoTEdgeHandler -Command "Browse-Project" }
            "2" { Invoke-IoTEdgeHandler -Command "Deploy-AzureIoTHub" }
            "3" { Invoke-IoTEdgeHandler -Command "Deploy-AzureIoTEdgeRuntime" }
            "4" { Invoke-IoTEdgeHandler -Command "Deploy-AzureIoTCentral" }
            "5" { Invoke-IoTEdgeHandler -Command "Deploy-AzureDigitalTwins" }
            "6" { Invoke-IoTEdgeHandler -Command "Deploy-AzureSphere" }
            "7" { Invoke-IoTEdgeHandler -Command "Deploy-AWSIoTCore" }
            "8" { Invoke-IoTEdgeHandler -Command "Deploy-AWSGreengrass" }
            "9" { Invoke-IoTEdgeHandler -Command "Deploy-GCPIoTCore" }
            "10" { Invoke-IoTEdgeHandler -Command "Deploy-EdgeComputingCluster" }
            "11" { Invoke-IoTEdgeHandler -Command "Deploy-AutoDetectIoTServices" }
            "12" { Invoke-IoTEdgeHandler -Command "Configure-IoTDeviceManagement" }
            "13" { Invoke-IoTEdgeHandler -Command "Show-IoTEdgeServiceTypeInfo" }
            "14" { Invoke-IoTEdgeHandler -Command "List-DeployedIoTEdgeServices" }
            default {
                Write-ColorOutput "Invalid selection: $($result.Choice)" -ForegroundColor Red
                Start-Sleep 2
            }
        }
    } while ($true)
}

function Show-MultiCloudHybrid {
    <#
    .SYNOPSIS
        Displays Layer 6: Multi-Cloud & Hybrid Services.
    #>
    [CmdletBinding()]
    param()
    
    $menuItems = @{
        "1"  = "Browse and Select Project"
        "2"  = "Deploy Multi-Cloud Infrastructure"
        "3"  = "Deploy Hybrid Cloud Bridge"
        "4"  = "Deploy Cross-Cloud Load Balancer"
        "5"  = "Deploy Multi-Cloud Monitoring"
        "6"  = "Deploy Cloud-Native Migration"
        "7"  = "Deploy Hybrid Kubernetes Cluster"
        "8"  = "Deploy Multi-Cloud Database"
        "9"  = "Deploy Cross-Cloud Security"
        "10" = "Deploy Hybrid Networking"
        "11" = "Auto-Detect and Deploy Multi-Cloud"
        "12" = "Configure Multi-Cloud Orchestration"
        "13" = "Show Multi-Cloud Service Type Info"
        "14" = "List Deployed Multi-Cloud Services"
    }
    
    do {
        Clear-Host
        
        Write-ColorOutput @"
        
╔══════════════════════════════════════════════════════════════════╗
║            LAYER 6: MULTI-CLOUD & HYBRID SERVICES               ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor DarkRed
        
        Write-ColorOutput ""
        Write-ColorOutput "  Multi-cloud and hybrid services for distributed applications." -ForegroundColor Gray
        Write-ColorOutput "  Deploy across multiple cloud providers and on-premises." -ForegroundColor Gray
        Write-ColorOutput ""
        
        try {
            $result = Show-Menu -Title "Multi-Cloud & Hybrid Options" -MenuItems $menuItems `
                -ExitOption "0" -ExitText "Return to Layer Selection" `
                -ValidateInput
        }
        catch {
            Write-ColorOutput "ERROR in Show-Menu call: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
        
        if ($result.IsExit -eq $true) {
            break
        }
        
        # Handle the menu selection
        switch ($result.Choice) {
            "1" { Invoke-MultiCloudHandler -Command "Browse-Project" }
            "2" { Invoke-MultiCloudHandler -Command "Deploy-MultiCloudInfrastructure" }
            "3" { Invoke-MultiCloudHandler -Command "Deploy-HybridCloudBridge" }
            "4" { Invoke-MultiCloudHandler -Command "Deploy-CrossCloudLoadBalancer" }
            "5" { Invoke-MultiCloudHandler -Command "Deploy-MultiCloudMonitoring" }
            "6" { Invoke-MultiCloudHandler -Command "Deploy-CloudNativeMigration" }
            "7" { Invoke-MultiCloudHandler -Command "Deploy-HybridKubernetesCluster" }
            "8" { Invoke-MultiCloudHandler -Command "Deploy-MultiCloudDatabase" }
            "9" { Invoke-MultiCloudHandler -Command "Deploy-CrossCloudSecurity" }
            "10" { Invoke-MultiCloudHandler -Command "Deploy-HybridNetworking" }
            "11" { Invoke-MultiCloudHandler -Command "Deploy-AutoDetectMultiCloud" }
            "12" { Invoke-MultiCloudHandler -Command "Configure-MultiCloudOrchestration" }
            "13" { Invoke-MultiCloudHandler -Command "Show-MultiCloudServiceTypeInfo" }
            "14" { Invoke-MultiCloudHandler -Command "List-DeployedMultiCloudServices" }
            default {
                Write-ColorOutput "Invalid selection: $($result.Choice)" -ForegroundColor Red
                Start-Sleep 2
            }
        }
    } while ($true)
}