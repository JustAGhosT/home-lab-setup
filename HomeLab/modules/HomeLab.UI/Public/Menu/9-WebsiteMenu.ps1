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
            "5" { Show-Layer5IoTEdge }
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
        Displays Layer 3: Database & Storage Services (Coming Soon).
    #>
    [CmdletBinding()]
    param()
    
    Clear-Host
    
    Write-ColorOutput @"
    
╔══════════════════════════════════════════════════════════════════╗
║              LAYER 3: DATABASE & STORAGE SERVICES                ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Blue
    
    Write-ColorOutput ""
    Write-ColorOutput "  🚧 This layer is coming soon! 🚧" -ForegroundColor Yellow
    Write-ColorOutput ""
    Write-ColorOutput "  Planned features:" -ForegroundColor White
    Write-ColorOutput "  • Azure SQL Database" -ForegroundColor Gray
    Write-ColorOutput "  • Azure Cosmos DB" -ForegroundColor Gray
    Write-ColorOutput "  • Azure Blob Storage" -ForegroundColor Gray
    Write-ColorOutput "  • Azure CDN" -ForegroundColor Gray
    Write-ColorOutput "  • AWS RDS" -ForegroundColor Gray
    Write-ColorOutput "  • AWS DynamoDB" -ForegroundColor Gray
    Write-ColorOutput "  • Google Cloud SQL" -ForegroundColor Gray
    Write-ColorOutput "  • Google Cloud Storage" -ForegroundColor Gray
    Write-ColorOutput ""
    Write-ColorOutput "  Press any key to return to layer selection..." -ForegroundColor Cyan
    
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Layer4AIMLAnalytics {
    <#
    .SYNOPSIS
        Displays Layer 4: AI/ML & Analytics Services (Coming Soon).
    #>
    [CmdletBinding()]
    param()
    
    Clear-Host
    
    Write-ColorOutput @"
    
╔══════════════════════════════════════════════════════════════════╗
║              LAYER 4: AI/ML & ANALYTICS SERVICES                 ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Magenta
    
    Write-ColorOutput ""
    Write-ColorOutput "  🚧 This layer is coming soon! 🚧" -ForegroundColor Yellow
    Write-ColorOutput ""
    Write-ColorOutput "  Planned features:" -ForegroundColor White
    Write-ColorOutput "  • Azure Cognitive Services" -ForegroundColor Gray
    Write-ColorOutput "  • Azure Machine Learning Studio" -ForegroundColor Gray
    Write-ColorOutput "  • Azure Stream Analytics" -ForegroundColor Gray
    Write-ColorOutput "  • AWS SageMaker" -ForegroundColor Gray
    Write-ColorOutput "  • AWS Comprehend" -ForegroundColor Gray
    Write-ColorOutput "  • Google Cloud AI Platform" -ForegroundColor Gray
    Write-ColorOutput "  • Google Cloud Vision API" -ForegroundColor Gray
    Write-ColorOutput ""
    Write-ColorOutput "  Press any key to return to layer selection..." -ForegroundColor Cyan
    
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Layer5IoTEdge {
    <#
    .SYNOPSIS
        Displays Layer 5: IoT & Edge Computing (Coming Soon).
    #>
    [CmdletBinding()]
    param()
    
    Clear-Host
    
    Write-ColorOutput @"
    
╔══════════════════════════════════════════════════════════════════╗
║              LAYER 5: IOT & EDGE COMPUTING                       ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    Write-ColorOutput ""
    Write-ColorOutput "  🚧 This layer is coming soon! 🚧" -ForegroundColor Yellow
    Write-ColorOutput ""
    Write-ColorOutput "  Planned features:" -ForegroundColor White
    Write-ColorOutput "  • Azure IoT Hub" -ForegroundColor Gray
    Write-ColorOutput "  • Azure IoT Edge" -ForegroundColor Gray
    Write-ColorOutput "  • Azure Digital Twins" -ForegroundColor Gray
    Write-ColorOutput "  • AWS IoT Core" -ForegroundColor Gray
    Write-ColorOutput "  • AWS Greengrass" -ForegroundColor Gray
    Write-ColorOutput "  • Google Cloud IoT Core" -ForegroundColor Gray
    Write-ColorOutput "  • Edge Computing Modules" -ForegroundColor Gray
    Write-ColorOutput ""
    Write-ColorOutput "  Press any key to return to layer selection..." -ForegroundColor Cyan
    
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-MultiCloudHybrid {
    <#
    .SYNOPSIS
        Displays Multi-Cloud & Hybrid Deployments (Coming Soon).
    #>
    [CmdletBinding()]
    param()
    
    Clear-Host
    
    Write-ColorOutput @"
    
╔══════════════════════════════════════════════════════════════════╗
║           MULTI-CLOUD & HYBRID DEPLOYMENTS                       ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor White
    
    Write-ColorOutput ""
    Write-ColorOutput "  🚧 This layer is coming soon! 🚧" -ForegroundColor Yellow
    Write-ColorOutput ""
    Write-ColorOutput "  Planned features:" -ForegroundColor White
    Write-ColorOutput "  • Cross-platform deployments" -ForegroundColor Gray
    Write-ColorOutput "  • Hybrid cloud configurations" -ForegroundColor Gray
    Write-ColorOutput "  • Multi-region deployments" -ForegroundColor Gray
    Write-ColorOutput "  • Disaster recovery setups" -ForegroundColor Gray
    Write-ColorOutput "  • Load balancing across clouds" -ForegroundColor Gray
    Write-ColorOutput "  • Unified monitoring" -ForegroundColor Gray
    Write-ColorOutput ""
    Write-ColorOutput "  Press any key to return to layer selection..." -ForegroundColor Cyan
    
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}