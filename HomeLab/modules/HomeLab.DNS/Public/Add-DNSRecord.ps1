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
    }
    catch {
        Write-Error "Failed to import HomeLab.Core module: $_"
        return
    }
    
    try {
        Import-Module HomeLab.Azure -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to import HomeLab.Azure module - $($_.Exception.Message)"
        return
    }
    
    # Set subscription context
    try {
        Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to set Azure subscription context to $SubscriptionId - $($_.Exception.Message)"
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
    
    # Initialize recordSet to null
    $recordSet = $null
    
    # Create record set based on type
    switch ($RecordType) {
        "A" {
            try {
                $recordSet = New-AzDnsRecordSet -Name $recordSetName -RecordType A -ZoneName $ZoneName -ResourceGroupName $ResourceGroup -Ttl $TTL -Overwrite -ErrorAction Stop
                Add-AzDnsRecordConfig -RecordSet $recordSet -Ipv4Address $Value
            }
            catch {
                Write-Error "Failed to create A record set: $_"
                return
            }
        }
        "CNAME" {
            try {
                $recordSet = New-AzDnsRecordSet -Name $recordSetName -RecordType CNAME -ZoneName $ZoneName -ResourceGroupName $ResourceGroup -Ttl $TTL -Overwrite -ErrorAction Stop
                Add-AzDnsRecordConfig -RecordSet $recordSet -Cname $Value
            }
            catch {
                Write-Error "Failed to create CNAME record set: $_"
                return
            }
        }
        "MX" {
            # Parse MX value (format: "priority hostname")
            $parts = $Value -split " ", 2
            if ($parts.Count -ne 2) {
                Write-Error "MX record value should be in format: 'priority hostname' (e.g., '10 mail.example.com')"
                return
            }

            # Validate priority is a valid integer
            $priority = $null
            if (-not [int]::TryParse($parts[0], [ref]$priority)) {
                Write-Error "MX record priority must be a valid integer. Provided value: '$($parts[0])'"
                return
            }

            # Validate priority is within valid range (0-65535)
            if ($priority -lt 0 -or $priority -gt 65535) {
                Write-Error "MX record priority must be between 0 and 65535. Provided value: $priority"
                return
            }

            $exchange = $parts[1]

            # Validate exchange hostname is not empty
            if ([string]::IsNullOrWhiteSpace($exchange)) {
                Write-Error "MX record exchange hostname cannot be empty"
                return
            }
            
            try {
                $recordSet = New-AzDnsRecordSet -Name $recordSetName -RecordType MX -ZoneName $ZoneName -ResourceGroupName $ResourceGroup -Ttl $TTL -Overwrite -ErrorAction Stop
                Add-AzDnsRecordConfig -RecordSet $recordSet -Exchange $exchange -Preference $priority
            }
            catch {
                Write-Error "Failed to create MX record set: $_"
                return
            }
        }
        "TXT" {
            try {
                $recordSet = New-AzDnsRecordSet -Name $recordSetName -RecordType TXT -ZoneName $ZoneName -ResourceGroupName $ResourceGroup -Ttl $TTL -Overwrite -ErrorAction Stop
                Add-AzDnsRecordConfig -RecordSet $recordSet -Value $Value
            }
            catch {
                Write-Error "Failed to create TXT record set: $_"
                return
            }
        }
    }
    
    # Check if recordSet was created successfully
    if ($null -eq $recordSet) {
        Write-Error "Failed to create DNS record set for $RecordName.$ZoneName ($RecordType)"
        return $null
    }
    
    # Save the record set
    try {
        Set-AzDnsRecordSet -RecordSet $recordSet -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to save DNS record set: $_"
        return $null
    }
    
    Write-Host "DNS record added successfully: $RecordName.$ZoneName ($RecordType)"
    return $recordSet
}