<#
.SYNOPSIS
    Creates an additional VPN client certificate.
.DESCRIPTION
    Creates a new client certificate signed by an existing root certificate found using a pattern.
    Exports the certificate to the specified path.
.PARAMETER NewClientName
    The name for the new client certificate.
.PARAMETER RootCertPattern
    Pattern to find the root certificate. Defaults to "*vpn-root*".
.PARAMETER ExportPath
    The path where the certificate will be exported. Defaults to %TEMP%.
.PARAMETER CertPassword
    Optional secure string password for the exported certificate.
.EXAMPLE
    Add-VpnClientCertificate -NewClientName "MyVPN-Client3"
.OUTPUTS
    Hashtable containing success status, certificate path, and thumbprint.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Add-VpnClientCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$NewClientName,
        
        [Parameter(Mandatory = $false)]
        [string]$RootCertPattern = "*vpn-root*",
        
        [Parameter(Mandatory = $false)]
        [string]$ExportPath = $env:TEMP,
        
        [Parameter(Mandatory = $false)]
        [securestring]$CertPassword
    )
    
    # Sanitize client name
    $safeClientName = Get-SanitizedCertName -Name $NewClientName
    
    # Log any name changes
    if ($safeClientName -ne $NewClientName) {
        Write-LogSafely -Message "Client name sanitized from '$NewClientName' to '$safeClientName'" -Level WARNING
    }
    
    Write-LogSafely -Message "Adding additional VPN client certificate: $safeClientName" -Level INFO
    
    # Validate export path
    if (-not (Confirm-ExportPath -Path $ExportPath)) {
        return @{ 
            Success = $false
            Message = "Failed to access or create export directory: $ExportPath"
        }
    }
    
    try {
        # Retrieve the existing root certificate using the provided pattern
        $rootCert = Get-ChildItem -Path Cert:\CurrentUser\My | 
                    Where-Object { $_.Subject -like "CN=$RootCertPattern" -or $_.Subject -like $RootCertPattern } | 
                    Select-Object -First 1
        
        if (-not $rootCert) {
            throw "No VPN root certificate found matching pattern '$RootCertPattern'."
        }
        
        Write-LogSafely -Message "Found root certificate: $($rootCert.Subject) with thumbprint: $($rootCert.Thumbprint)" -Level DEBUG
        
        # Create a new client certificate signed by the root certificate.
        $clientCert = New-SelfSignedCertificate -Subject "CN=$safeClientName" `
                                               -CertStoreLocation "Cert:\CurrentUser\My" `
                                               -Signer $rootCert `
                                               -KeyExportPolicy Exportable `
                                               -KeyLength 2048 `
                                               -HashAlgorithm SHA256 `
                                               -NotAfter (Get-Date).AddYears(2)
        
        Write-LogSafely -Message "Additional VPN client certificate created with thumbprint: $($clientCert.Thumbprint)" -Level INFO
        
        # If a path was provided, export the certificate
        if ($ExportPath) {
            $clientPfxPath = Join-Path -Path $ExportPath -ChildPath "$safeClientName.pfx"
            
            # If no password is provided, prompt for one securely
            if (-not $CertPassword) {
                $CertPassword = Read-Host -Prompt "Enter password for certificate export" -AsSecureString
            }
            
            Export-PfxCertificate -Cert $clientCert -FilePath $clientPfxPath -Password $CertPassword | Out-Null
            Write-LogSafely -Message "Exported client certificate to: $clientPfxPath" -Level INFO
            
            return @{
                Success = $true
                Message = "Additional client certificate created and exported."
                ClientCertThumbprint = $clientCert.Thumbprint
                ClientCertPath = $clientPfxPath
                ClientCertName = $safeClientName
            }
        }
        
        return @{
            Success = $true
            Message = "Additional client certificate created."
            ClientCertThumbprint = $clientCert.Thumbprint
            ClientCertName = $safeClientName
        }
    }
    catch {
        Write-LogSafely -Message "Error adding additional VPN client certificate: $_" -Level ERROR
        return @{ Success = $false; Message = "Failed to add additional client certificate: $_"; Error = $_ }
    }
}
