<#
.SYNOPSIS
    Helper functions for HomeLab.Security module
.DESCRIPTION
    Contains internal helper functions used by the HomeLab.Security module.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

function Get-CertificateData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CertificatePath
    )
    
    try {
        $certContent = Get-Content -Path $CertificatePath -Raw
        $certData = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($certContent))
        return $certData
    }
    catch {
        Write-Log "Error reading certificate data: $_" -Level ERROR
        return $null
    }
}
