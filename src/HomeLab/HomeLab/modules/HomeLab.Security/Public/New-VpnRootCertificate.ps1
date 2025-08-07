<#
.SYNOPSIS
    Creates a new VPN root certificate and an initial client certificate.
.DESCRIPTION
    Creates a self-signed root certificate and an initial client certificate for VPN authentication.
    Exports both certificates to the specified path.
.PARAMETER RootCertName
    The name for the root certificate.
.PARAMETER ClientCertName
    The name for the initial client certificate.
.PARAMETER CreateNewRoot
    If specified, creates a new root certificate even if one already exists.
.PARAMETER ExportPath
    The path where certificates will be exported. Defaults to %TEMP%.
.PARAMETER CertPassword
    Optional secure string password for the exported certificates.
.EXAMPLE
    New-VpnRootCertificate -RootCertName "MyVPN-Root" -ClientCertName "MyVPN-Client"
.OUTPUTS
    Hashtable containing success status, certificate paths, and thumbprints.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function New-VpnRootCertificate {
    [CmdletBinding()]
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
    
    # Sanitize certificate names
    $safeRootCertName = Get-SanitizedCertName -Name $RootCertName
    $safeClientCertName = Get-SanitizedCertName -Name $ClientCertName
    
    # Log any name changes
    if ($safeRootCertName -ne $RootCertName) {
        Write-LogSafely -Message "Root certificate name sanitized from '$RootCertName' to '$safeRootCertName'" -Level WARNING
    }
    
    if ($safeClientCertName -ne $ClientCertName) {
        Write-LogSafely -Message "Client certificate name sanitized from '$ClientCertName' to '$safeClientCertName'" -Level WARNING
    }
    
    Write-LogSafely -Message "Creating new VPN root certificate: $safeRootCertName with client certificate: $safeClientCertName" -Level INFO
    
    # Validate export path
    if (-not (Confirm-ExportPath -Path $ExportPath)) {
        return @{ 
            Success = $false
            Message = "Failed to access or create export directory: $ExportPath"
        }
    }
    
    try {
        # Create a self-signed root certificate in the CurrentUser store valid for 5 years.
        $rootCert = New-SelfSignedCertificate -Subject "CN=$safeRootCertName" `
                                              -CertStoreLocation "Cert:\CurrentUser\My" `
                                              -KeyExportPolicy Exportable `
                                              -KeyUsage CertSign, CRLSign, DigitalSignature `
                                              -KeyUsageProperty All `
                                              -KeyLength 2048 `
                                              -HashAlgorithm SHA256 `
                                              -NotAfter (Get-Date).AddYears(5)
                                                
        if ($CreateNewRoot) {
            Write-LogSafely -Message "A new root certificate was created with thumbprint: $($rootCert.Thumbprint)" -Level INFO
        }
        
        # Export the root certificate as a PFX file with a secure password
        $pfxPath = Join-Path -Path $ExportPath -ChildPath "$safeRootCertName.pfx"
        
        # If no password is provided, prompt for one securely
        if (-not $CertPassword) {
            $CertPassword = Read-Host -Prompt "Enter password for certificate export" -AsSecureString
        }
        
        Export-PfxCertificate -Cert $rootCert -FilePath $pfxPath -Password $CertPassword | Out-Null
        Write-LogSafely -Message "Exported root certificate to: $pfxPath" -Level INFO
        
        # Also export the public certificate (CER) for VPN gateway configuration
        $cerPath = Join-Path -Path $ExportPath -ChildPath "$safeRootCertName.cer"
        Export-Certificate -Cert $rootCert -FilePath $cerPath -Type CERT | Out-Null
        Write-LogSafely -Message "Exported public certificate to: $cerPath" -Level INFO
        
        # Also export as Base64 encoded text file for Azure VPN Gateway
        $txtPath = Join-Path -Path $ExportPath -ChildPath "$safeRootCertName.txt"
        $certData = [System.Convert]::ToBase64String($rootCert.Export('Cert'))
        [System.IO.File]::WriteAllText($txtPath, $certData)
        Write-LogSafely -Message "Exported Base64 encoded certificate to: $txtPath" -Level INFO
        
        # Immediately create an initial client certificate signed by the root certificate, valid for 2 years.
        $clientCert = New-SelfSignedCertificate -Subject "CN=$safeClientCertName" `
                                               -CertStoreLocation "Cert:\CurrentUser\My" `
                                               -Signer $rootCert `
                                               -KeyExportPolicy Exportable `
                                               -KeyLength 2048 `
                                               -HashAlgorithm SHA256 `
                                               -NotAfter (Get-Date).AddYears(2)
        
        Write-LogSafely -Message "Created initial client certificate with thumbprint: $($clientCert.Thumbprint)" -Level INFO
        
        # Export the client certificate as well
        $clientPfxPath = Join-Path -Path $ExportPath -ChildPath "$safeClientCertName.pfx"
        Export-PfxCertificate -Cert $clientCert -FilePath $clientPfxPath -Password $CertPassword | Out-Null
        Write-LogSafely -Message "Exported client certificate to: $clientPfxPath" -Level INFO
        
        return @{
            Success = $true
            Message = "Root and initial client certificate created."
            RootCertThumbprint = $rootCert.Thumbprint
            ClientCertThumbprint = $clientCert.Thumbprint
            RootCertPath = $pfxPath
            RootCerPath = $cerPath
            RootTxtPath = $txtPath
            ClientCertPath = $clientPfxPath
            RootCertName = $safeRootCertName
            ClientCertName = $safeClientCertName
        }
    }
    catch {
        Write-LogSafely -Message "Error creating VPN root certificate: $_" -Level ERROR
        return @{ Success = $false; Message = "Failed to create root certificate: $_"; Error = $_ }
    }
}
