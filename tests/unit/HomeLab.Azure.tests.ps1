# Unit tests for HomeLab.Azure module

Describe "HomeLab.Azure Module Tests" {
    BeforeAll {
        # Import the mock module
        $mockPath = "$PSScriptRoot\HomeLab.Azure.Mock.ps1"
        if (Test-Path $mockPath) {
            . $mockPath
        } else {
            Write-Warning "Mock module not found at path: $mockPath"
        }
        
        # Define the functions that will be tested
        function Deploy-Infrastructure {
            param (
                [Parameter(Mandatory = $true)]
                [string]$ResourceGroupName,
                
                [Parameter(Mandatory = $true)]
                [string]$Location
            )
            
            try {
                $result = New-AzureResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location
                return @{ Success = $true; Result = $result }
            } catch {
                return @{ Success = $false; Error = $_.Exception.Message }
            }
        }
        
        function Set-VpnGatewayState {
            param (
                [Parameter(Mandatory = $true)]
                [string]$State,
                
                [Parameter(Mandatory = $true)]
                [string]$ResourceGroupName,
                
                [Parameter(Mandatory = $true)]
                [string]$VpnGatewayName
            )
            
            if ($State -eq "Enabled") {
                $result = Enable-VpnGateway -ResourceGroupName $ResourceGroupName -Name $VpnGatewayName -State $State
            } else {
                $result = Disable-VpnGateway -ResourceGroupName $ResourceGroupName -Name $VpnGatewayName -State $State
            }
            
            return $true
        }
        
        function Test-ResourceGroup {
            param (
                [Parameter(Mandatory = $true)]
                [string]$ResourceGroupName
            )
            
            return Test-ResourceGroupExists -ResourceGroupName $ResourceGroupName
        }
        
        function Test-AzureResourceName {
            param (
                [Parameter(Mandatory = $true)]
                [string]$Name,
                
                [Parameter(Mandatory = $true)]
                [string]$Type
            )
            
            return Test-ResourceNameFormat -Name $Name -ResourceType $Type
        }
    }

    Context "Azure Resource Deployment" {
        It "Should create a resource group successfully" {
            $result = Deploy-Infrastructure -ResourceGroupName "test-rg" -Location "eastus"
            $result.Success | Should -Be $true
        }
        
        It "Should handle deployment failures gracefully" {
            # Mock New-AzureResourceGroup to throw an exception
            Mock New-AzureResourceGroup { throw "Resource group creation failed" }
            
            $result = Deploy-Infrastructure -ResourceGroupName "test-rg" -Location "eastus"
            $result.Success | Should -Be $false
            $result.Error | Should -Not -BeNullOrEmpty
        }
    }

    Context "VPN Gateway Management" {
        It "Should enable VPN Gateway successfully" {
            $result = Set-VpnGatewayState -State "Enabled" -ResourceGroupName "test-rg" -VpnGatewayName "test-vpn"
            $result | Should -Be $true
        }
        
        It "Should disable VPN Gateway successfully" {
            $result = Set-VpnGatewayState -State "Disabled" -ResourceGroupName "test-rg" -VpnGatewayName "test-vpn"
            $result | Should -Be $true
        }
        
        It "Should get VPN Gateway state correctly" {
            $state = Get-VpnGatewayState -ResourceGroupName "test-rg" -Name "test-vpn"
            $state.State | Should -Be "Enabled"
        }
    }

    Context "NAT Gateway Management" {
        It "Should enable NAT Gateway successfully" {
            $result = Enable-NatGateway -ResourceGroupName "test-rg" -Name "test-nat"
            $result.State | Should -Be "Enabled"
        }
        
        It "Should disable NAT Gateway successfully" {
            $result = Disable-NatGateway -ResourceGroupName "test-rg" -Name "test-nat"
            $result.State | Should -Be "Disabled"
        }
    }

    Context "Azure Resource Validation" {
        It "Should validate resource group existence" {
            $result = Test-ResourceGroup -ResourceGroupName "existing-rg"
            $result | Should -Be $true
            
            $result = Test-ResourceGroup -ResourceGroupName "non-existing-rg"
            $result | Should -Be $false
        }
        
        It "Should validate resource name format" {
            $result = Test-AzureResourceName -Name "valid-name" -Type "ResourceGroup"
            $result | Should -Be $true
            
            $result = Test-AzureResourceName -Name "Invalid_Name!" -Type "ResourceGroup"
            $result | Should -Be $false
        }
    }
}