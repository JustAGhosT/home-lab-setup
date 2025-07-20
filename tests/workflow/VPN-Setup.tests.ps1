# Workflow tests for VPN setup process

Describe "VPN Setup Workflow Tests" {
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
        
        # Setup test configuration
        $testConfig = @{
            Environment = "test"
            Location = "eastus"
            ProjectName = "homelab-test"
            LocationCode = "eus"
            ResourceGroupName = "rg-homelab-test"
            VpnGatewayName = "vpn-homelab-test"
        } | ConvertTo-Json
        
        Set-Content -Path $script:TestConfigPath -Value $testConfig
        
        # Mock configuration path
        Mock Get-ConfigPath { return $script:TestConfigPath }
        
        # Mock certificate path
        Mock Get-CertificatePath { return $script:TestCertPath }
        
        # Mock Azure commands
        Mock az { return '{"provisioningState": "Succeeded"}' }
        Mock Connect-AzAccount { return $true }
        Mock Get-AzContext { return @{ Subscription = @{ Id = "00000000-0000-0000-0000-000000000000" } } }
        
        # Mock VPN commands
        Mock Add-VpnConnection { return $true }
        Mock Remove-VpnConnection { return $true }
        Mock Get-VpnConnection { return @{ Name = "TestVPN"; ConnectionStatus = "Connected" } }
    }
    
    Context "Complete VPN Setup Workflow" {
        It "Should deploy network infrastructure" {
            # Mock deployment functions
            Mock Deploy-NetworkComponent { return @{ Success = $true } }
            
            # Deploy network
            $result = Deploy-Infrastructure -Component "Network"
            $result.Success | Should -Be $true
        }
        
        It "Should deploy VPN Gateway" {
            # Mock deployment functions
            Mock Deploy-VPNGatewayComponent { return @{ Success = $true } }
            
            # Deploy VPN Gateway
            $result = Deploy-Infrastructure -Component "VPNGateway"
            $result.Success | Should -Be $true
        }
        
        It "Should create and configure root certificate" {
            # Create root certificate
            $rootCert = New-VpnRootCertificate -Name "WorkflowTestRoot"
            $rootCert | Should -Not -BeNullOrEmpty
            
            # Add to VPN Gateway
            Mock Add-VpnGatewayCertificate { return $true }
            $result = Add-VpnGatewayCertificate -Certificate $rootCert
            $result | Should -Be $true
        }
        
        It "Should create client certificate and configure VPN client" {
            # Create root certificate
            $rootCert = New-VpnRootCertificate -Name "WorkflowTestRoot"
            
            # Create client certificate
            $clientCert = New-VpnClientCertificate -Name "WorkflowTestClient" -RootCertificate $rootCert
            $clientCert | Should -Not -BeNullOrEmpty
            
            # Add computer to VPN
            $result = Add-VpnComputer -Name "WorkflowTestComputer" -Certificate $clientCert
            $result | Should -Be $true
        }
        
        It "Should connect to and disconnect from VPN" {
            # Connect to VPN
            $connectResult = Connect-Vpn -Name "TestVPN"
            $connectResult | Should -Be $true
            
            # Check connection status
            $status = Get-VpnConnectionStatus -Name "TestVPN"
            $status | Should -Be "Connected"
            
            # Disconnect from VPN
            $disconnectResult = Disconnect-Vpn -Name "TestVPN"
            $disconnectResult | Should -Be $true
        }
    }
}