function Get-CertificatePath {
    <#
    .SYNOPSIS
        Gets the path where certificates are stored.
    
    .DESCRIPTION
        This function returns the path where VPN certificates are stored.
        It uses the VpnCertificatesPath variable if set, otherwise defaults to a path in the user profile.
    
    .EXAMPLE
        $certPath = Get-CertificatePath
    #>
    [CmdletBinding()]
    param()
    
    # Check if the VpnCertificatesPath variable is defined
    if (Get-Variable -Name VpnCertificatesPath -ErrorAction SilentlyContinue) {
        return $VpnCertificatesPath
    }
    
    # Default path if variable is not set
    $defaultPath = Join-Path -Path $env:USERPROFILE -ChildPath "HomeLab\Certificates"
    
    # Create the directory if it doesn't exist
    if (-not (Test-Path -Path $defaultPath)) {
        New-Item -Path $defaultPath -ItemType Directory -Force | Out-Null
    }
    
    return $defaultPath
}