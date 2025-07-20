# Unit tests for HomeLab.Security module

Describe "HomeLab.Security Module Tests" {
    BeforeAll {
        # Import the mock module
        $mockPath = "$PSScriptRoot\HomeLab.Security.Mock.ps1"
        if (Test-Path $mockPath) {
            . $mockPath
        } else {
            Write-Warning "Mock module not found at path: $mockPath"
        }
        
        # Create test directory for file operations
        $script:TestDir = "$env:TEMP\HomeLab-Security-Tests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
    }
    
    Context "Certificate Generation" {
        It "Should create a root certificate" {
            $rootCert = New-VpnRootCertificate -CertificateName "TestRoot"
            $rootCert | Should -Not -BeNullOrEmpty
            $rootCert.Subject | Should -Match "CN=TestRoot"
        }
        
        It "Should create a client certificate" {
            $clientCert = New-VpnClientCertificate -ClientName "TestClient" -RootCertificateName "TestRoot"
            $clientCert | Should -Not -BeNullOrEmpty
            $clientCert.Subject | Should -Match "CN=TestClient"
        }
        
        It "Should sanitize certificate names" {
            $sanitized = Get-SanitizedCertName -Name "Test Certificate 123!@#"
            $sanitized | Should -Be "TestCertificate123"
        }
    }
    
    Context "VPN Gateway Certificate Management" {
        It "Should add a certificate to the VPN gateway" {
            $result = Add-VpnGatewayCertificate -ResourceGroupName "test-rg" -VpnGatewayName "test-vpn" -RootCertificateName "TestRoot"
            $result | Should -Be $true
        }
    }
    
    Context "VPN Client Management" {
        It "Should add a computer to the VPN" {
            $result = Add-VpnComputer -ComputerName "TestComputer" -ClientCertificateName "TestClient"
            $result | Should -Be $true
        }
        
        It "Should connect to the VPN" {
            $result = Connect-Vpn -ConnectionName "HomeLab VPN"
            $result | Should -Be $true
        }
        
        It "Should disconnect from the VPN" {
            $result = Disconnect-Vpn -ConnectionName "HomeLab VPN"
            $result | Should -Be $true
        }
        
        It "Should get VPN connection status" {
            $status = Get-VpnConnectionStatus -ConnectionName "HomeLab VPN"
            $status.Status | Should -Be "Connected"
        }
    }
    
    Context "Certificate Management" {
        It "Should list certificates" {
            $certs = Get-VpnCertificate
            $certs | Should -Not -BeNullOrEmpty
            $certs.Count | Should -BeGreaterThan 0
        }
        
        It "Should filter certificates by type" {
            $rootCerts = Get-VpnCertificate -CertificateType "Root"
            $rootCerts | Should -Not -BeNullOrEmpty
            $rootCerts[0].Type | Should -Be "Root"
            
            $clientCerts = Get-VpnCertificate -CertificateType "Client"
            $clientCerts | Should -Not -BeNullOrEmpty
            $clientCerts[0].Type | Should -Be "Client"
        }
    }
    
    AfterAll {
        # Clean up test directory if it exists
        if (Test-Path -Path $script:TestDir) {
            Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}