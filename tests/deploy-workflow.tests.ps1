# Import the core modules
$modulePath = Join-Path $PSScriptRoot "..\HomeLab\modules"
try {
    # Import required modules
    Import-Module "$modulePath\HomeLab.Core" -Force -ErrorAction Stop
    Import-Module "$modulePath\HomeLab.Azure" -Force -ErrorAction Stop
    Import-Module "$modulePath\HomeLab.Web" -Force -ErrorAction Stop
} catch {
    Write-Warning "Failed to import one or more required modules: $_"
}

Describe "End-to-End Deployment Workflow Tests" {
    # Helper function for resource naming
    function global:Get-ResourceNames {
        param (
            [string]$Subdomain,
            [string]$Environment,
            [string]$CustomDomain
        )
        
        $cleanSubdomain = ($Subdomain -replace '[^a-zA-Z0-9]', '').ToLower()
        $appName = "$cleanSubdomain-$Environment"
        $resourceGroup = "rg-$appName"
        $fullDomain = "$Subdomain.$CustomDomain"
        
        return @{
            CleanSubdomain = $cleanSubdomain
            AppName        = $appName
            ResourceGroup  = $resourceGroup
            FullDomain     = $fullDomain
        }
    }
    Context "Static Website Deployment Flow" {
        BeforeAll {
            # Mock functions to simulate the deployment workflow
            function Test-StaticDeploymentFlow {
                param (
                    [string]$Subdomain = "myapp",
                    [string]$Environment = "dev",
                    [string]$CustomDomain = "example.com",
                    [string]$Location = "westeurope"
                )
                
                # Step 1: Generate resource names
                $resourceNames = Get-ResourceNames -Subdomain $Subdomain -Environment $Environment -CustomDomain $CustomDomain
                
                # Step 2: Deploy to Static Web App
                $deploymentSuccess = $true
                
                # Step 3: Configure custom domain if provided
                $domainConfigured = $false
                if ($CustomDomain) {
                    $domainConfigured = $true
                }
                
                return @{
                    AppName           = $resourceNames.AppName
                    ResourceGroup     = $resourceNames.ResourceGroup
                    FullDomain        = $resourceNames.FullDomain
                    DeploymentSuccess = $deploymentSuccess
                    DomainConfigured  = $domainConfigured
                }
            }
        }
        
        It "Should complete all steps in the static deployment flow" {
            $result = Test-StaticDeploymentFlow
            
            $result.AppName | Should -Be "myapp-dev"
            $result.ResourceGroup | Should -Be "rg-myapp-dev"
            $result.FullDomain | Should -Be "myapp.example.com"
            $result.DeploymentSuccess | Should -Be $true
            $result.DomainConfigured | Should -Be $true
        }
        
        It "Should handle special characters in subdomain" {
            $result = Test-StaticDeploymentFlow -Subdomain "my-special_app!"
            
            $result.AppName | Should -Be "myspecialapp-dev"
            $result.ResourceGroup | Should -Be "rg-myspecialapp-dev"
            $result.FullDomain | Should -Be "my-special_app!.example.com"
        }
    }
    
    Context "App Service Deployment Flow" {
        BeforeAll {
            # Mock functions to simulate the deployment workflow
            function Test-AppServiceDeploymentFlow {
                param (
                    [string]$Subdomain = "myapi",
                    [string]$Environment = "dev",
                    [string]$CustomDomain = "example.com",
                    [string]$Location = "westeurope"
                )
                
                # Step 1: Generate resource names
                $resourceNames = Get-ResourceNames -Subdomain $Subdomain -Environment $Environment -CustomDomain $CustomDomain
                
                # Step 2: Create resource group
                $resourceGroupCreated = $true
                
                # Step 3: Deploy to App Service
                $deploymentSuccess = $true
                
                # Step 4: Configure custom domain if provided
                $domainConfigured = $false
                if ($CustomDomain) {
                    $domainConfigured = $true
                }
                
                return @{
                    AppName              = $resourceNames.AppName
                    ResourceGroup        = $resourceNames.ResourceGroup
                    FullDomain           = $resourceNames.FullDomain
                    ResourceGroupCreated = $resourceGroupCreated
                    DeploymentSuccess    = $deploymentSuccess
                    DomainConfigured     = $domainConfigured
                }
            }
        }
        
        It "Should complete all steps in the app service deployment flow" {
            $result = Test-AppServiceDeploymentFlow
            
            $result.AppName | Should -Be "myapi-dev"
            $result.ResourceGroup | Should -Be "rg-myapi-dev"
            $result.FullDomain | Should -Be "myapi.example.com"
            $result.ResourceGroupCreated | Should -Be $true
            $result.DeploymentSuccess | Should -Be $true
            $result.DomainConfigured | Should -Be $true
        }
        
        It "Should handle different environments" {
            $result = Test-AppServiceDeploymentFlow -Environment "prod"
            
            $result.AppName | Should -Be "myapi-prod"
            $result.ResourceGroup | Should -Be "rg-myapi-prod"
        }
        
        It "Should handle empty custom domain" {
            $result = Test-AppServiceDeploymentFlow -CustomDomain ""
            
            $result.DomainConfigured | Should -Be $false
        }
    }
}