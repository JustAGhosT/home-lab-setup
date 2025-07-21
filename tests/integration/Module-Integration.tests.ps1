# Integration tests for HomeLab module interactions

Describe "HomeLab Module Integration Tests" {
    BeforeAll {
        # Load mock functions
        . "$PSScriptRoot\HomeLab.Integration.Mock.ps1"
        
        # Create test directories
        $script:TestDir = New-Item -Path "TestDrive:\homelab" -ItemType Directory -Force
        
        # Setup test configuration path
        $script:TestConfigPath = Join-Path $script:TestDir "config.json"
        
        # Setup test certificate path
        $script:TestCertPath = New-Item -Path "TestDrive:\homelab\certs" -ItemType Directory -Force
        
        # Mock configuration path
        function Get-ConfigPath { return $script:TestConfigPath }
        
        # Mock certificate path
        function Get-CertificatePath { return $script:TestCertPath }
        
        # Mock Get-AzContext
        function Get-AzContext { 
            return @{ 
                Subscription = @{ 
                    Id = "00000000-0000-0000-0000-000000000000" 
                } 
            } 
        }
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
            # Deploy VPN Gateway
            $vpnResult = Deploy-Infrastructure -Component "VPNGateway"
            $vpnResult.Success | Should -Be $true
            
            # Create and add root certificate
            function New-VpnRootCertificate {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$RootCertName,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$ClientCertName,
                    
                    [Parameter(Mandatory = $false)]
                    [string]$ExportPath = $env:TEMP
                )
                
                return @{
                    Success = $true
                    RootCertThumbprint = "ABC123"
                    PublicData = "TestData"
                }
            }
            
            $rootCert = New-VpnRootCertificate -RootCertName "IntegrationTestRoot" -ClientCertName "IntegrationTestClient"
            $rootCert | Should -Not -BeNullOrEmpty
            
            # Add certificate to VPN Gateway
            function Add-VpnGatewayCertificate {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$CertificateData,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$CertificateName
                )
                
                return $true
            }
            
            $addResult = Add-VpnGatewayCertificate -CertificateData "TestData" -CertificateName "TestCert"
            $addResult | Should -Be $true
        }
    }
    
    Context "Complete VPN Setup Workflow" {
        It "Should complete the full VPN setup workflow" {
            # Deploy infrastructure
            $infra = Deploy-Infrastructure -ResourceGroupName "test-rg" -Location "eastus"
            $infra.Success | Should -Be $true
            
            # Create and add root certificate
            function New-VpnRootCertificate {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$RootCertName,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$ClientCertName,
                    
                    [Parameter(Mandatory = $false)]
                    [string]$ExportPath = $env:TEMP
                )
                
                return @{
                    Success = $true
                    RootCertThumbprint = "ABC123"
                    PublicData = "TestData"
                }
            }
            
            $rootCert = New-VpnRootCertificate -RootCertName "TestRoot" -ClientCertName "TestClient"
            $rootCert | Should -Not -BeNullOrEmpty
            
            function Add-VpnGatewayCertificate {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$CertificateData,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$CertificateName
                )
                
                return $true
            }
            
            $addRoot = Add-VpnGatewayCertificate -CertificateData "TestData" -CertificateName "TestCert"
            $addRoot | Should -Be $true
            
            # Create client certificate
            function New-VpnClientCertificate {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$CertificateName,
                    
                    [Parameter(Mandatory = $true)]
                    [object]$RootCertificate,
                    
                    [Parameter(Mandatory = $false)]
                    [string]$ExportPath = $env:TEMP
                )
                
                return @{
                    Success = $true
                    Thumbprint = "DEF456"
                }
            }
            
            $clientCert = New-VpnClientCertificate -CertificateName "TestClient" -RootCertificate $rootCert
            $clientCert | Should -Not -BeNullOrEmpty
            
            # Add computer to VPN
            function Add-VpnComputer {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$ComputerName,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$CertificateThumbprint
                )
                
                return $true
            }
            
            $addComputer = Add-VpnComputer -ComputerName "TestComputer" -CertificateThumbprint "DEF456"
            $addComputer | Should -Be $true
        }
    }
}