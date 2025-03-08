<#
.SYNOPSIS
    Uploads a certificate to an Azure VPN Gateway.
.DESCRIPTION
    Uploads a public certificate to an Azure VPN Gateway for P2S VPN authentication.
.PARAMETER ResourceGroupName
    The resource group containing the VPN gateway.
.PARAMETER GatewayName
    The name of the VPN gateway.
.PARAMETER CertificateName
    The name to give the certificate in Azure.
.PARAMETER CertificateData
    The Base64-encoded certificate data.
.EXAMPLE
    Add-VpnGatewayCertificate -ResourceGroupName "MyRG" -GatewayName "MyVPN" -CertificateName "RootCert" -CertificateData $certData
.OUTPUTS
    Hashtable containing success status and message.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Add-VpnGatewayCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$GatewayName,
        
        [Parameter(Mandatory = $true)]
        [string]$CertificateName,
        
        [Parameter(Mandatory = $true)]
        [string]$CertificateData
    )
    
    # Sanitize certificate name
    $safeCertName = Get-SanitizedCertName -Name $CertificateName
    
    # Log any name changes
    if ($safeCertName -ne $CertificateName) {
        Write-LogSafely -Message "Certificate name sanitized from '$CertificateName' to '$safeCertName'" -Level WARNING
    }
    
    Write-LogSafely -Message "Uploading certificate '$safeCertName' to VPN Gateway '$GatewayName' in resource group '$ResourceGroupName'" -Level INFO
    
    # Validate certificate data is Base64 encoded
    try {
        # Try to decode the Base64 string to ensure it's valid
        $null = [System.Convert]::FromBase64String($CertificateData)
    }
    catch {
        Write-LogSafely -Message "Certificate data is not valid Base64. Error: $_" -Level ERROR
        return @{ 
            Success = $false
            Message = "Invalid certificate data format. Must be Base64 encoded."
            Error = $_ 
        }
    }
    
    try {
        # First check if Azure CLI is installed
        $azCheck = $null
        try {
            $azCheck = & az --version 2>&1
        }
        catch {
            throw "Azure CLI is not installed or not in the PATH. Please install Azure CLI and try again."
        }
        
        if (-not $azCheck) {
            throw "Azure CLI is not installed or not in the PATH. Please install Azure CLI and try again."
        }
        
        # Check if user is logged in
        $loginCheck = $null
        try {
            $loginCheck = & az account show 2>&1
        }
        catch {
            Write-LogSafely -Message "Not logged in to Azure. Prompting for login." -Level WARNING
        }
        
        if (-not $loginCheck) {
            Write-LogSafely -Message "Not logged in to Azure. Prompting for login." -Level WARNING
            & az login | Out-Null
        }
        
        # Create a temporary file for the certificate data to avoid command injection
        $tempCertFile = Join-Path -Path $env:TEMP -ChildPath "vpn_cert_$([Guid]::NewGuid().ToString()).txt"
        [System.IO.File]::WriteAllText($tempCertFile, $CertificateData)
        
        try {
            # Use the Azure CLI to upload the certificate from the file
            $result = & az network vnet-gateway root-cert create `
                --resource-group $ResourceGroupName `
                --gateway-name $GatewayName `
                --name $safeCertName `
                --public-cert-data "@$tempCertFile"
            
            if ($LASTEXITCODE -eq 0) {
                Write-LogSafely -Message "VPN gateway certificate uploaded successfully" -Level INFO
                return @{ 
                    Success = $true
                    Message = "VPN gateway certificate uploaded."
                    CertificateName = $safeCertName
                }
            }
            else {
                throw "Azure CLI command failed with exit code $LASTEXITCODE"
            }
        }
        finally {
            # Clean up the temporary file
            if (Test-Path $tempCertFile) {
                Remove-Item -Path $tempCertFile -Force
            }
        }
    }
    catch {
        Write-LogSafely -Message "Error uploading VPN gateway certificate: $_" -Level ERROR
        return @{ 
            Success = $false
            Message = "Failed to upload VPN gateway certificate: $_"
            Error = $_ 
        }
    }
}
