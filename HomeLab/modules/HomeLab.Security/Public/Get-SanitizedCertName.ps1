<#
.SYNOPSIS
    Sanitizes certificate names to ensure they are valid.
.DESCRIPTION
    Removes invalid characters from certificate names and ensures they start with a letter.
.PARAMETER Name
    The certificate name to sanitize.
.EXAMPLE
    $safeName = Get-SanitizedCertName -Name "My Certificate!"
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Get-SanitizedCertName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # Remove any characters that could cause issues in certificate subject names
    $sanitized = $Name -replace '[^\w\d\-_]', ''
    
    # Ensure the name starts with a letter
    if ($sanitized -notmatch '^[a-zA-Z]') {
        $sanitized = "cert" + $sanitized
    }
    
    return $sanitized
}