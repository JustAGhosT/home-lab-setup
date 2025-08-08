<#
.SYNOPSIS
    Creates a new VPN client certificate signed by an existing root certificate.
.DESCRIPTION
    Creates a client certificate signed by the specified root certificate for VPN authentication.
    Exports the certificate to the specified path.
.PARAMETER RootCertName
    The name of the existing root certificate to use for signing.
.PARAMETER ClientCertName
    The name for the new client certificate.
.PARAMETER ExportPath
    The path where the certificate will be exported. Defaults to %TEMP%.
.PARAMETER CertPassword
    Optional secure string password for the exported certificate.
.EXAMPLE
    New-VpnClientCertificate -RootCertName "MyVPN-Root" -ClientCertName "MyVPN-Client2"
.OUTPUTS
    Hashtable containing success status, certificate path, and thumbprint.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function New-VpnClientCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootCertName,
        
        [Parameter(Mandatory = $true)]
        [string]$ClientCertName,
        
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
    
    Write-LogSafely -Message "Creating new VPN client certificate: $safeClientCertName using root certificate: $safeRootCertName" -Level INFO
    
    # Validate export path if specified
    if ($ExportPath -and -not (Confirm-ExportPath -Path $ExportPath)) {
        return @{ 
            Success = $false
            Message = "Failed to access or create export directory: $ExportPath"
        }
    }
    
    try {
        # Retrieve the specified root certificate from the CurrentUser store.
        $rootCert = Get-ChildItem -Path Cert:\CurrentUser\My | 
                    Where-Object { $_.Subject -eq "CN=$safeRootCertName" -or $_.Subject -eq "CN=$RootCertName" } | 
                    Select-Object -First 1
        
        if (-not $rootCert) {
            throw "Root certificate '$safeRootCertName' not found in certificate store."
        }
        
        # Create a new client certificate signed by the retrieved root certificate.
        $clientCert = New-SelfSignedCertificate -Subject "CN=$safeClientCertName" `
                                               -CertStoreLocation "Cert:\CurrentUser\My" `
                                               -Signer $rootCert `
                                               -KeyExportPolicy Exportable `
                                               -KeyLength 2048 `
                                               -HashAlgorithm SHA256 `
                                               -NotAfter (Get-Date).AddYears(2)
        
        Write-LogSafely -Message "VPN client certificate created with thumbprint: $($clientCert.Thumbprint)" -Level INFO
        
        # If an export path was provided, export the certificate
        if ($ExportPath) {
            $clientPfxPath = Join-Path -Path $ExportPath -ChildPath "$safeClientCertName.pfx"
            
            # If no password is provided, prompt for one securely
            if (-not $CertPassword) {
                $CertPassword = Read-Host -Prompt "Enter password for certificate export" -AsSecureString
            }
            
            Export-PfxCertificate -Cert $clientCert -FilePath $clientPfxPath -Password $CertPassword | Out-Null
            Write-LogSafely -Message "Exported client certificate to: $clientPfxPath" -Level INFO
            
            return @{
                Success = $true
                Message = "Client certificate created and exported."
                ClientCertThumbprint = $clientCert.Thumbprint
                ClientCertPath = $clientPfxPath
                ClientCertName = $safeClientCertName
            }
        }
        
        return @{
            Success = $true
            Message = "Client certificate created."
            ClientCertThumbprint = $clientCert.Thumbprint
            ClientCertName = $safeClientCertName
        }
    }
    catch {
        Write-LogSafely -Message "Error creating VPN client certificate: $_" -Level ERROR
        return @{ Success = $false; Message = "Failed to create client certificate: $_"; Error = $_ }
    }
}
