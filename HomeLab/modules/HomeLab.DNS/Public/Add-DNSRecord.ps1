function Add-DNSRecord {
    <#
    .SYNOPSIS
        Adds a DNS record to an Azure DNS zone.
    
    .DESCRIPTION
        This function adds a DNS record (A, CNAME, MX, TXT) to an Azure DNS zone.
    
    .PARAMETER ZoneName
        The DNS zone name (e.g., example.com).
    
    .PARAMETER RecordName
        The record name (e.g., www for www.example.com).
    
    .PARAMETER RecordType
        The record type (A, CNAME, MX, TXT).
    
    .PARAMETER Value
        The record value (IP address for A, hostname for CNAME, etc.).
    
    .PARAMETER TTL
        Time to live in seconds. Default is 3600 (1 hour).
    
    .PARAMETER ResourceGroup
        Azure Resource Group name.
    
    .PARAMETER SubscriptionId
        Azure subscription ID.
    
    .EXAMPLE
        Add-DNSRecord -ZoneName "example.com" -RecordName "www" -RecordType "A" -Value "192.168.1.1" -ResourceGroup "myResourceGroup" -SubscriptionId "00000000-0000-0000-0000-000000000000"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ZoneName,
        
        [Parameter(Mandatory = $true)]
        [string]$RecordName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("A", "CNAME", "MX", "TXT")]
        [string]$RecordType,
        
        [Parameter(Mandatory = $true)]
        [string]$Value,
        
        [Parameter()]
        [int]$TTL = 3600,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId
    )
    
    # Import required modules
    try {
        Import-Module HomeLab.Core -ErrorAction Stop
    } catch {
        Write-Error "Failed to import HomeLab.Core module: $_"
        return
    }
    
    try {
        Import-Module HomeLab.Azure -ErrorAction Stop
    } catch {
        Write-Error "Failed to import HomeLab.Azure module: $_"
        return
    }
    
    # Set subscription context
    try {
        Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
    } catch {
        Write-Error "Failed to set Azure subscription context to $SubscriptionId: $_"
        return
    }
    
    # Check if DNS zone exists
    $dnsZone = Get-AzDnsZone -Name $ZoneName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
    
    if (-not $dnsZone) {
        Write-Error "DNS zone $ZoneName does not exist in resource group $ResourceGroup."
        return
    }
    
    # Handle @ symbol for root domain
    if ($RecordName -eq "@") {
        $recordSetName = "@"
    }
    else {
        $recordSetName = $RecordName
    }
    
    # Create record set based on type
    switch ($RecordType) {
        "A" {
            $recordSet = New-AzDnsRecordSet -Name $recordSetName -RecordType A -ZoneName $ZoneName -ResourceGroupName $ResourceGroup -Ttl $TTL -Overwrite
            Add-AzDnsRecordConfig -RecordSet $recordSet -Ipv4Address $Value
        }
        "CNAME" {
            $recordSet = New-AzDnsRecordSet -Name $recordSetName -RecordType CNAME -ZoneName $ZoneName -ResourceGroupName $ResourceGroup -Ttl $TTL -Overwrite
            Add-AzDnsRecordConfig -RecordSet $recordSet -Cname $Value
        }
        "MX" {
            # Parse MX value (format: "priority hostname")
            $parts = $Value -split " ", 2
            if ($parts.Count -ne 2) {
                Write-Error "MX record value should be in format: 'priority hostname' (e.g., '10 mail.example.com')"
                return
            }
            
            $priority = [int]$parts[0]
            $exchange = $parts[1]
            
            $recordSet = New-AzDnsRecordSet -Name $recordSetName -RecordType MX -ZoneName $ZoneName -ResourceGroupName $ResourceGroup -Ttl $TTL -Overwrite
            Add-AzDnsRecordConfig -RecordSet $recordSet -Exchange $exchange -Preference $priority
        }
        "TXT" {
            $recordSet = New-AzDnsRecordSet -Name $recordSetName -RecordType TXT -ZoneName $ZoneName -ResourceGroupName $ResourceGroup -Ttl $TTL -Overwrite
            Add-AzDnsRecordConfig -RecordSet $recordSet -Value $Value
        }
    }
    
    # Save the record set
    Set-AzDnsRecordSet -RecordSet $recordSet
    
    Write-Host "DNS record added successfully: $RecordName.$ZoneName ($RecordType)"
    return $recordSet
}