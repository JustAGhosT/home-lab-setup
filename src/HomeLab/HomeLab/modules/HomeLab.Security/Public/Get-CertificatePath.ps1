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
    
    # Default path if variable is not set - use cross-platform home directory
    $homeDir = if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
        $env:USERPROFILE 
    } else {
        $env:HOME 
    }
    
    $defaultPath = Join-Path -Path $homeDir -ChildPath "HomeLab" | Join-Path -ChildPath "Certificates"
    
    # Create the directory if it doesn't exist
    if (-not (Test-Path -Path $defaultPath)) {
        try {
            Write-Verbose "Creating certificate directory: $defaultPath"
            New-Item -Path $defaultPath -ItemType Directory -Force | Out-Null
        } catch {
            throw "Failed to create certificate directory '$defaultPath': $_"
        }
    }
    
    return $defaultPath
}