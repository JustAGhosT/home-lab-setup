# Mock functions for HomeLab.Security module

# Certificate storage paths
$script:VpnCertificatesPath = "$env:USERPROFILE\HomeLab\Certificates"
$script:VpnConfigPath = "$env:USERPROFILE\HomeLab\VpnConfig"
$script:VpnDefaultValidity = 365
$script:VpnDefaultKeySize = 2048

function Get-CertificatePath {
    param (
        [Parameter(Mandatory = $false)]
        [string]$CertificateType = "Root",
        
        [Parameter(Mandatory = $false)]
        [string]$CertificateName = "HomeLab-VPN-Root"
    )
    
    $path = Join-Path -Path $script:VpnCertificatesPath -ChildPath "$CertificateType\$CertificateName.pfx"
    return $path
}

function New-VpnRootCertificate {
    param (
        [Parameter(Mandatory = $false)]
        [string]$CertificateName = "HomeLab-VPN-Root",
        
        [Parameter(Mandatory = $false)]
        [int]$ValidityInDays = 3650,
        
        [Parameter(Mandatory = $false)]
        [int]$KeySize = 2048,
        
        [Parameter(Mandatory = $false)]
        [string]$Password = "P@ssw0rd",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Return a mock certificate object
    return @{
        Subject = "CN=$CertificateName"
        Thumbprint = "0123456789ABCDEF0123456789ABCDEF01234567"
        NotBefore = (Get-Date)
        NotAfter = (Get-Date).AddDays($ValidityInDays)
        HasPrivateKey = $true
        Path = Get-CertificatePath -CertificateType "Root" -CertificateName $CertificateName
    }
}

function New-VpnClientCertificate {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ClientName,
        
        [Parameter(Mandatory = $false)]
        [string]$RootCertificateName = "HomeLab-VPN-Root",
        
        [Parameter(Mandatory = $false)]
        [int]$ValidityInDays = 365,
        
        [Parameter(Mandatory = $false)]
        [int]$KeySize = 2048,
        
        [Parameter(Mandatory = $false)]
        [string]$Password = "P@ssw0rd",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Return a mock certificate object
    return @{
        Subject = "CN=$ClientName"
        Thumbprint = "FEDCBA9876543210FEDCBA9876543210FEDCBA98"
        NotBefore = (Get-Date)
        NotAfter = (Get-Date).AddDays($ValidityInDays)
        HasPrivateKey = $true
        Path = Get-CertificatePath -CertificateType "Client" -CertificateName $ClientName
    }
}

function Get-VpnCertificate {
    param (
        [Parameter(Mandatory = $false)]
        [string]$CertificateType = "All"
    )
    
    $certificates = @()
    
    if ($CertificateType -eq "Root" -or $CertificateType -eq "All") {
        $certificates += [PSCustomObject]@{
            Type = "Root"
            Name = "HomeLab-VPN-Root"
            Thumbprint = "0123456789ABCDEF0123456789ABCDEF01234567"
            NotBefore = (Get-Date).AddDays(-30)
            NotAfter = (Get-Date).AddDays(3650)
            Path = Get-CertificatePath -CertificateType "Root" -CertificateName "HomeLab-VPN-Root"
        }
    }
    
    if ($CertificateType -eq "Client" -or $CertificateType -eq "All") {
        $certificates += [PSCustomObject]@{
            Type = "Client"
            Name = "TestClient1"
            Thumbprint = "FEDCBA9876543210FEDCBA9876543210FEDCBA98"
            NotBefore = (Get-Date).AddDays(-10)
            NotAfter = (Get-Date).AddDays(365)
            Path = Get-CertificatePath -CertificateType "Client" -CertificateName "TestClient1"
        }
        
        $certificates += [PSCustomObject]@{
            Type = "Client"
            Name = "TestClient2"
            Thumbprint = "ABCDEF0123456789ABCDEF0123456789ABCDEF01"
            NotBefore = (Get-Date).AddDays(-5)
            NotAfter = (Get-Date).AddDays(365)
            Path = Get-CertificatePath -CertificateType "Client" -CertificateName "TestClient2"
        }
    }
    
    return $certificates
}

function Add-VpnGatewayCertificate {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$VpnGatewayName,
        
        [Parameter(Mandatory = $false)]
        [string]$RootCertificateName = "HomeLab-VPN-Root"
    )
    
    # Return success
    return $true
}

function Add-VpnClientCertificate {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ClientName,
        
        [Parameter(Mandatory = $false)]
        [string]$CertificatePath,
        
        [Parameter(Mandatory = $false)]
        [string]$Password = "P@ssw0rd"
    )
    
    # Return success
    return $true
}

function Add-VpnComputer {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $false)]
        [string]$ClientCertificateName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Return success
    return $true
}

function Connect-Vpn {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConnectionName = "HomeLab VPN"
    )
    
    # Return success
    return $true
}

function Disconnect-Vpn {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConnectionName = "HomeLab VPN"
    )
    
    # Return success
    return $true
}

function Get-VpnConnectionStatus {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConnectionName = "HomeLab VPN"
    )
    
    # Return connected status
    return @{
        Name = $ConnectionName
        Status = "Connected"
        ConnectionTime = (Get-Date).AddMinutes(-30)
    }
}

# Helper functions
function Get-SanitizedCertName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # Remove invalid characters
    $sanitized = $Name -replace '[^a-zA-Z0-9\-_]', ''
    return $sanitized
}

function Get-CertificateData {
    param (
        [Parameter(Mandatory = $true)]
        [string]$CertificatePath,
        
        [Parameter(Mandatory = $false)]
        [string]$Password = "P@ssw0rd"
    )
    
    # Return mock certificate data
    return "MIICXAIBAAKBgQC+8pdU..."
}

function Confirm-ExportPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    # Create directory if it doesn't exist
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
    
    return $true
}

function Write-LogSafely {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Level = "Info"
    )
    
    # Just return the message for testing
    return "$Level - $Message"
}

# No need to export functions in a dot-sourced script