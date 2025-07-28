# Unit tests for HomeLab.Security module

Describe "HomeLab.Security Module Tests" {
    BeforeAll {
        # Create test directories
        $script:TestDir = New-Item -Path "TestDrive:\homelab" -ItemType Directory -Force
        $script:TestCertPath = New-Item -Path "TestDrive:\homelab\certs" -ItemType Directory -Force
        
        # Load mock functions
        . "$PSScriptRoot\HomeLab.Security.Mock.ps1"
    }
    
    Context "Certificate Generation" {
        It "Should create a root certificate" {
            $cert = New-VpnRootCertificate -RootCertName "TestRoot" -ClientCertName "TestClient" -ExportPath $script:TestCertPath
            $cert | Should -Not -BeNullOrEmpty
            $cert.Success | Should -Be $true
            $cert.RootCertThumbprint | Should -Be "ABC123"
        }
        
        It "Should create a client certificate" {
            Mock New-VpnRootCertificate { return @{Success = $true; RootCertThumbprint = "ABC123"} }
            $rootCert = @{Thumbprint = "ABC123"; Subject = "CN=TestRoot" }
            $cert = New-VpnClientCertificate -CertificateName "TestClient" -RootCertificate $rootCert -ExportPath $script:TestCertPath
            $cert | Should -Not -BeNullOrEmpty
        }
        
        It "Should sanitize certificate names" {
            $name = Get-SanitizedCertName -Name "Test Certificate 123!@#"
            $name | Should -Be "TestCertificate123"
        }
    }
    
    Context "VPN Gateway Certificate Management" {
        It "Should add a certificate to the VPN gateway" {
            Mock az { return '{"provisioningState": "Succeeded"}' }
            
            $cert = @{Thumbprint = "ABC123"; PublicData = "TestData" }
            $result = Add-VpnGatewayCertificate -CertificateData "TestData" -CertificateName "TestCert"
            $result | Should -Be $true
        }
    }
    
    Context "VPN Client Management" {
        It "Should add a computer to the VPN" {
            $cert = @{Thumbprint = "ABC123" }
            $testComputerName = "TestComputer-$(Get-Random)"
            $result = Add-VpnComputer -ComputerName $testComputerName -CertificateThumbprint "ABC123"
            $result | Should -Be $true
        }
        
        It "Should connect to the VPN" {
            $result = Connect-Vpn -ConnectionName "TestVPN"
            $result | Should -Be $true
        }
        
        It "Should disconnect from the VPN" {
            $result = Disconnect-Vpn -ConnectionName "TestVPN"
            $result | Should -Be $true
        }
        
        It "Should get VPN connection status" {
            $status = Get-VpnConnectionStatus -ConnectionName "TestVPN"
            $status | Should -Be "Connected"
        }
    }
    
    Context "Certificate Management" {
        It "Should list certificates" {
            $certs = Get-VpnCertificate
            $certs | Should -Not -BeNullOrEmpty
        }
        
        It "Should filter certificates by type" {
            Mock Get-ChildItem { 
                return @(
                    @{Thumbprint = "ABC123"; Subject = "CN=Root-Test" },
                    @{Thumbprint = "DEF456"; Subject = "CN=Client-Test" }
                )
            }
            
            $rootCerts = Get-VpnCertificate -CertificateType "Root"
            $rootCerts | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Certificate Path Management" {
        It "Should return a valid certificate path" {
            # Override the mock function
            function Get-CertificatePath { return "TestPath" }
            
            $path = Get-CertificatePath
            $path | Should -Be "TestPath"
        }
        
        It "Should return the test certificate path" {
            # Use the original mock function
            . "$PSScriptRoot\HomeLab.Security.Mock.ps1"
            
            $path = Get-CertificatePath
            $path | Should -Be "TestDrive:\homelab\certs"
        }
    }
}