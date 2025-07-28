function New-DNSZone {
    <#
    .SYNOPSIS
        Creates a new DNS zone in Azure.
    
    .DESCRIPTION
        This function creates a new DNS zone in Azure and returns the name servers.
    
    .PARAMETER DomainName
        The domain name for the DNS zone (e.g., example.com).
    
    .PARAMETER ResourceGroup
        Azure Resource Group name.
    
    .PARAMETER SubscriptionId
        Azure subscription ID.
    
    .EXAMPLE
        New-DNSZone -DomainName "example.com" -ResourceGroup "myResourceGroup" -SubscriptionId "00000000-0000-0000-0000-000000000000"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DomainName,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId
    )
    
    # Import required modules
    Import-Module HomeLab.Core
    Import-Module HomeLab.Azure
    
    # Set subscription context
    Set-AzContext -SubscriptionId $SubscriptionId
    
    # Check if DNS zone already exists
    $existingZone = Get-AzDnsZone -Name $DomainName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
    
    if ($existingZone) {
        Write-Host "DNS zone $DomainName already exists."
        $dnsZone = $existingZone
        $nameServers = $existingZone.NameServers
    }
    else {
        # Create new DNS zone
        Write-Host "Creating DNS zone: $DomainName"
        $dnsZone = New-AzDnsZone -Name $DomainName -ResourceGroupName $ResourceGroup
        $nameServers = $dnsZone.NameServers
    }
    
    # Display name servers
    Write-Host "DNS Zone created successfully. Please configure your domain registrar with these name servers:"
    foreach ($ns in $nameServers) {
        Write-Host "  $ns"
    }
    
    return $dnsZone
}