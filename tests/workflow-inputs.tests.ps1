Describe "Workflow Input Validation Tests" {
    Context "Resource Name Generation" {
        BeforeAll {
            # Mock function to simulate the GitHub workflow's name generation
            function New-ResourceNames {
                param (
                    [string]$Subdomain,
                    [string]$Environment,
                    [string]$CustomDomain
                )
                
                # Clean subdomain (remove non-alphanumeric chars)
                $cleanSubdomain = $Subdomain -replace '[^a-zA-Z0-9]', '' -replace '[A-Z]', { $_.Value.ToLower() }
                
                # Generate names
                $appName = "$cleanSubdomain-$Environment"
                $resourceGroup = "rg-$appName"
                $fullDomain = "$Subdomain.$CustomDomain"
                
                return @{
                    AppName = $appName
                    ResourceGroup = $resourceGroup
                    FullDomain = $fullDomain
                }
            }
        }
        
        It "Should generate correct resource names with simple inputs" {
            $result = New-ResourceNames -Subdomain "myapp" -Environment "dev" -CustomDomain "example.com"
            
            $result.AppName | Should -Be "myapp-dev"
            $result.ResourceGroup | Should -Be "rg-myapp-dev"
            $result.FullDomain | Should -Be "myapp.example.com"
        }
        
        It "Should clean subdomain by removing special characters" {
            $result = New-ResourceNames -Subdomain "my-app_123!" -Environment "prod" -CustomDomain "example.com"
            
            $result.AppName | Should -Be "myapp123-prod"
            $result.ResourceGroup | Should -Be "rg-myapp123-prod"
            $result.FullDomain | Should -Be "my-app_123!.example.com"
        }
        
        It "Should convert uppercase to lowercase in app name" {
            $result = New-ResourceNames -Subdomain "MyApp" -Environment "staging" -CustomDomain "example.com"
            
            $result.AppName | Should -Be "myapp-staging"
            $result.ResourceGroup | Should -Be "rg-myapp-staging"
            $result.FullDomain | Should -Be "MyApp.example.com"
        }
    }
    
    Context "Deployment Type Detection" {
        BeforeAll {
            # Mock function to simulate the GitHub workflow's deployment type detection
            function Test-DeploymentType {
                param (
                    [string]$InputType,
                    [bool]$HasPackageJson = $false,
                    [bool]$HasRequirementsTxt = $false,
                    [bool]$HasCsprojFile = $false,
                    [string]$PackageJsonContent = ""
                )
                
                if ($InputType -ne "auto") {
                    return $InputType
                }
                
                if ($HasPackageJson) {
                    if ($PackageJsonContent -match "express|koa|fastify|hapi|nest") {
                        return "appservice"
                    }
                    elseif ($PackageJsonContent -match "next|react|vue|angular") {
                        return "static"
                    }
                    else {
                        return "static"
                    }
                }
                elseif ($HasRequirementsTxt) {
                    if (Test-Path "wsgi.py" -or Test-Path "asgi.py" -or Test-Path "manage.py") {
                        return "appservice"
                    }
                    else {
                        return "static"
                    }
                }
                elseif ($HasCsprojFile) {
                    return "appservice"
                }
                else {
                    return "static"
                }
            }
        }
        
        It "Should use explicit deployment type when provided" {
            Test-DeploymentType -InputType "static" | Should -Be "static"
            Test-DeploymentType -InputType "appservice" | Should -Be "appservice"
        }
        
        It "Should detect Node.js backend app as appservice" {
            $packageJson = '{"dependencies": {"express": "^4.17.1"}}'
            Test-DeploymentType -InputType "auto" -HasPackageJson $true -PackageJsonContent $packageJson | Should -Be "appservice"
        }
        
        It "Should detect React frontend app as static" {
            $packageJson = '{"dependencies": {"react": "^17.0.2"}}'
            Test-DeploymentType -InputType "auto" -HasPackageJson $true -PackageJsonContent $packageJson | Should -Be "static"
        }
        
        It "Should detect .NET app as appservice" {
            Test-DeploymentType -InputType "auto" -HasCsprojFile $true | Should -Be "appservice"
        }
        
        It "Should default to static when no specific indicators are found" {
            Test-DeploymentType -InputType "auto" | Should -Be "static"
        }
    }
}