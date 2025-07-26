# Mock functions for HomeLab.Security module tests

function Get-SanitizedCertName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # Simple mock implementation
    $sanitized = $Name -replace '[^\w\d\-_]', ''
    return $sanitized
}

function New-VpnRootCertificate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootCertName,
        
        [Parameter(Mandatory = $true)]
        [string]$ClientCertName,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateNewRoot,
        
        [Parameter(Mandatory = $false)]
        [string]$ExportPath = $env:TEMP,
        
        [Parameter(Mandatory = $false)]
        [securestring]$CertPassword
    )
    
    return @{
        Success = $true
        Message = "Root and initial client certificate created."
        RootCertThumbprint = "ABC123"
        ClientCertThumbprint = "DEF456"
        RootCertPath = "$ExportPath\$RootCertName.pfx"
        RootCertCerPath = "$ExportPath\$RootCertName.cer"
        RootTxtPath = "$ExportPath\$RootCertName.txt"
        ClientCertPath = "$ExportPath\$ClientCertName.pfx"
        RootCertName = $RootCertName
        ClientCertName = $ClientCertName
    }
}

function New-VpnClientCertificate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CertificateName,
        
        [Parameter(Mandatory = $true)]
        [object]$RootCertificate,
        
        [Parameter(Mandatory = $false)]
        [string]$ExportPath = $env:TEMP,
        
        [Parameter(Mandatory = $false)]
        [securestring]$CertPassword
    )
    
    return @{
        Success = $true
        Message = "Client certificate created."
        Thumbprint = "DEF456"
        CertificatePath = "$ExportPath\$CertificateName.pfx"
        CertificateName = $CertificateName
    }
}

function Add-VpnGatewayCertificate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CertificateData,
        
        [Parameter(Mandatory = $true)]
        [string]$CertificateName
    )
    
    return $true
}

function Add-VpnComputer {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [string]$CertificateThumbprint
    )
    
    return $true
}

function Connect-Vpn {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConnectionName
    )
    
    return $true
}

function Disconnect-Vpn {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConnectionName
    )
    
    return $true
}

function Get-VpnConnectionStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConnectionName
    )
    
    return "Connected"
}

function Get-VpnCertificate {
    param(
        [Parameter(Mandatory = $false)]
        [string]$CertificateType
    )
    
    if ($CertificateType -eq "Root") {
        return @(@{Thumbprint = "ABC123"; Subject = "CN=Root-Test" })
    }
    
    return @(@{Thumbprint = "ABC123"; Subject = "CN=Test" })
}

function Get-CertificatePath {
    return "TestDrive:\homelab\certs"
}