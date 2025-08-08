<#
.SYNOPSIS
    Retrieves VPN certificates from the certificate store.
.DESCRIPTION
    Gets VPN certificates from the CurrentUser certificate store, with optional filtering.
.PARAMETER CertificatePattern
    Optional pattern to filter certificates by name.
.PARAMETER RootCertificatesOnly
    If specified, returns only root certificates.
.PARAMETER ClientCertificatesOnly
    If specified, returns only client certificates.
.EXAMPLE
    Get-VpnCertificate -RootCertificatesOnly
.EXAMPLE
    Get-VpnCertificate -CertificatePattern "MyVPN*"
.OUTPUTS
    Hashtable containing success status and certificates.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Get-VpnCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CertificatePattern,
        
        [Parameter(Mandatory = $false)]
        [switch]$RootCertificatesOnly,
        
        [Parameter(Mandatory = $false)]
        [switch]$ClientCertificatesOnly
    )
    
    Write-LogSafely -Message "Retrieving VPN certificates from certificate store" -Level INFO
    
    # Check for conflicting parameters
    if ($RootCertificatesOnly -and $ClientCertificatesOnly) {
        Write-LogSafely -Message "Both RootCertificatesOnly and ClientCertificatesOnly specified. These options are mutually exclusive." -Level WARNING
        return @{
            Success = $false
            Message = "Conflicting parameters: Cannot specify both RootCertificatesOnly and ClientCertificatesOnly."
            Certificates = @()
        }
    }
    
    try {
        $certificates = Get-ChildItem -Path Cert:\CurrentUser\My -ErrorAction Stop
        
        # Filter by pattern if provided
        if ($CertificatePattern) {
            $certificates = $certificates | Where-Object { $_.Subject -like "*$CertificatePattern*" }
        }
        
        # Filter by certificate type if requested
        if ($RootCertificatesOnly) {
            $certificates = $certificates | Where-Object { $_.HasPrivateKey -and $_.Subject -like "*vpn-root*" }
        }
        
        if ($ClientCertificatesOnly) {
            $certificates = $certificates | Where-Object { $_.HasPrivateKey -and $_.Subject -notlike "*vpn-root*" }
        }
        
        Write-LogSafely -Message "Retrieved $($certificates.Count) certificates matching criteria" -Level INFO
        
        return @{
            Success = $true
            Message = "Retrieved $($certificates.Count) certificates."
            Certificates = $certificates
        }
    }
    catch {
        Write-LogSafely -Message "Error retrieving VPN certificates: $_" -Level ERROR
        return @{
            Success = $false
            Message = "Failed to retrieve certificates: $_"
            Error = $_
            Certificates = @()
        }
    }
}
