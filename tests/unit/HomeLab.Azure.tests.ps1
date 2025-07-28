# Unit tests for HomeLab.Azure module

Describe "HomeLab.Azure Module Tests" {
    BeforeAll {
        # Import the actual HomeLab.Azure module
        Import-Module "$PSScriptRoot\..\..\HomeLab\modules\HomeLab.Azure" -Force
        
        # Import the mock module for Azure cmdlets
        $mockPath = "$PSScriptRoot\HomeLab.Azure.Mock.ps1"
        if (Test-Path $mockPath) {
            . $mockPath
        } else {
            Write-Warning "Mock module not found at path: $mockPath"
        }
    }

    Context "Azure Resource Deployment" {
        It "Should deploy infrastructure successfully" {
            $result = Deploy-Infrastructure -ResourceGroupName "test-rg" -Location "eastus"
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "VPN Gateway Management" {
        It "Should set VPN Gateway state successfully" {
            $result = Set-VpnGatewayState -State "Enabled" -ResourceGroupName "test-rg" -VpnGatewayName "test-vpn"
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Should get VPN Gateway state correctly" {
            $state = Get-VpnGatewayState -ResourceGroupName "test-rg" -Name "test-vpn"
            $state | Should -Not -BeNullOrEmpty
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
        It "Should test resource group existence" {
            $result = Test-ResourceGroup -ResourceGroupName "existing-rg"
            $result | Should -Not -BeNullOrEmpty
        }
    }
}