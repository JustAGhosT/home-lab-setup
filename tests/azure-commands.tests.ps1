Describe "Azure Command Tests" {
    Context "Static Web App Commands" {
        BeforeAll {
            # Mock function to simulate the Azure CLI command for custom domain configuration
            function Test-StaticWebAppDomainCommand {
                param (
                    [string]$AppName,
                    [string]$ResourceGroup,
                    [string]$Hostname
                )
                
                $command = "az staticwebapp hostname set --name `"$AppName`" --resource-group `"$ResourceGroup`" --hostname `"$Hostname`""
                return $command
            }
        }
        
        It "Should generate correct Azure CLI command for static web app custom domain" {
            $command = Test-StaticWebAppDomainCommand -AppName "myapp-dev" -ResourceGroup "rg-myapp-dev" -Hostname "myapp.example.com"
            
            $expectedCommand = 'az staticwebapp hostname set --name "myapp-dev" --resource-group "rg-myapp-dev" --hostname "myapp.example.com"'
            $command | Should -Be $expectedCommand
        }
    }
    
    Context "App Service Commands" {
        BeforeAll {
            # Mock function to simulate the Azure CLI command for resource group creation
            function Test-ResourceGroupCommand {
                param (
                    [string]$ResourceGroup,
                    [string]$Location
                )
                
                $command = "az group create --name `"$ResourceGroup`" --location `"$Location`""
                return $command
            }
            
            # Mock function to simulate the Azure CLI command for custom domain configuration
            function Test-AppServiceDomainCommand {
                param (
                    [string]$AppName,
                    [string]$ResourceGroup,
                    [string]$Hostname
                )
                
                $command = "az webapp config hostname add --name `"$AppName`" --resource-group `"$ResourceGroup`" --hostname `"$Hostname`""
                return $command
            }
        }
        
        It "Should generate correct Azure CLI command for resource group creation" {
            $command = Test-ResourceGroupCommand -ResourceGroup "rg-myapp-dev" -Location "eastus"
            
            $expectedCommand = 'az group create --name "rg-myapp-dev" --location "eastus"'
            $command | Should -Be $expectedCommand
        }
        
        It "Should generate correct Azure CLI command for app service custom domain" {
            $command = Test-AppServiceDomainCommand -AppName "myapp-dev" -ResourceGroup "rg-myapp-dev" -Hostname "myapp.example.com"
            
            $expectedCommand = 'az webapp config hostname add --name "myapp-dev" --resource-group "rg-myapp-dev" --hostname "myapp.example.com"'
            $command | Should -Be $expectedCommand
        }
    }
}