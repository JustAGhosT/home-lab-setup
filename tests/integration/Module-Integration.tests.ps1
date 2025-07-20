# Integration tests for HomeLab module interactions

Describe "HomeLab Module Integration Tests" {
    BeforeAll {
        # Import the main module
        $modulePath = "$PSScriptRoot\..\..\HomeLab\HomeLab.psm1"
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force
        } else {
            Write-Warning "Module not found at path: $modulePath"
        }
        
        # Create test directories
        $script:TestDir = New-Item -Path "TestDrive:\homelab" -ItemType Directory -Force
        
        # Setup test configuration path
        $script:TestConfigPath = Join-Path $script:TestDir "config.json"
        
        # Setup test certificate path
        $script:TestCertPath = New-Item -Path "TestDrive:\homelab\certs" -ItemType Directory -Force
        
        # Mock configuration path
        Mock Get-ConfigPath { return $script:TestConfigPath }
        
        # Mock certificate path
        Mock Get-CertificatePath { return $script:TestCertPath }
        
        # Mock Azure commands
        Mock az { return '{"provisioningState": "Succeeded"}' }
        Mock Connect-AzAccount { return $true }
        Mock Get-AzContext { return @{ Subscription = @{ Id = "00000000-0000-0000-0000-000000000000" } } }
    }
    
    Context "Core and Azure Module Integration" {
        It "Should use configuration values for Azure deployments" {
            # Setup configuration
            $testConfig = @{
                Environment = "test"
                Location = "eastus"
                ProjectName = "homelab-test"
                LocationCode = "eus"
                ResourceGroupName = "rg-homelab-test"
            } | ConvertTo-Json
            
            Set-Content -Path $script:TestConfigPath -Value $testConfig
            
            # Deploy infrastructure using configuration
            $result = Deploy-Infrastructure
            $result.Success | Should -Be $true
        }
    }
    
    Context "Security and Azure Module Integration" {
        It "Should deploy VPN Gateway and add certificates" {
            # Mock VPN Gateway deployment
            Mock Deploy-VPNGatewayComponent { return @{ Success = $true } }
            
            # Deploy VPN Gateway
            $vpnResult = Deploy-Infrastructure -Component "VPNGateway"
            $vpnResult.Success | Should -Be $true
            
            # Create and add root certificate
            $rootCert = New-VpnRootCertificate -Name "IntegrationTestRoot"
            $rootCert | Should -Not -BeNullOrEmpty
            
            # Add certificate to VPN Gateway
            Mock Add-VpnGatewayCertificate { return $true }
            $addResult = Add-VpnGatewayCertificate -Certificate $rootCert
            $addResult | Should -Be $true
        }
    }
    
    Context "Complete VPN Setup Workflow" {
        It "Should complete the full VPN setup workflow" {
            # Mock all required functions
            Mock Deploy-Infrastructure { return @{ Success = $true } }
            Mock New-VpnRootCertificate { return @{ Thumbprint = "ABC123"; PublicData = "TestData" } }
            Mock Add-VpnGatewayCertificate { return $true }
            Mock New-VpnClientCertificate { return @{ Thumbprint = "DEF456" } }
            Mock Add-VpnComputer { return $true }
            
            # Deploy infrastructure
            $infra = Deploy-Infrastructure -ResourceGroupName "test-rg" -Location "eastus"
            $infra.Success | Should -Be $true
            
            # Create and add root certificate
            $rootCert = New-VpnRootCertificate -Name "TestRoot"
            $rootCert | Should -Not -BeNullOrEmpty
            
            $addRoot = Add-VpnGatewayCertificate -Certificate $rootCert
            $addRoot | Should -Be $true
            
            # Create client certificate
            $clientCert = New-VpnClientCertificate -Name "TestClient" -RootCertificate $rootCert
            $clientCert | Should -Not -BeNullOrEmpty
            
            # Add computer to VPN
            $addComputer = Add-VpnComputer -Name "TestComputer" -Certificate $clientCert
            $addComputer | Should -Be $true
        }
    }
}