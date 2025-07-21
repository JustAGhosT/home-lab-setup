function Get-DNSRecords {
    <#
    .SYNOPSIS
        Gets DNS records from an Azure DNS zone.
    
    .DESCRIPTION
        This function retrieves DNS records from an Azure DNS zone.
    
    .PARAMETER ZoneName
        The DNS zone name (e.g., example.com).
    
    .PARAMETER RecordType
        Optional. The record type to filter by (A, CNAME, MX, TXT).
    
    .PARAMETER ResourceGroup
        Azure Resource Group name.
    
    .PARAMETER SubscriptionId
        Azure subscription ID.
    
    .EXAMPLE
        Get-DNSRecords -ZoneName "example.com" -ResourceGroup "myResourceGroup" -SubscriptionId "00000000-0000-0000-0000-000000000000"
    
    .EXAMPLE
        Get-DNSRecords -ZoneName "example.com" -RecordType "A" -ResourceGroup "myResourceGroup" -SubscriptionId "00000000-0000-0000-0000-000000000000"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ZoneName,
        
        [Parameter()]
        [ValidateSet("A", "CNAME", "MX", "TXT", "All")]
        [string]$RecordType = "All",
        
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
    
    # Check if DNS zone exists
    $dnsZone = Get-AzDnsZone -Name $ZoneName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
    
    if (-not $dnsZone) {
        Write-Error "DNS zone $ZoneName does not exist in resource group $ResourceGroup."
        return @()
    }
    
    # Get record sets
    if ($RecordType -eq "All") {
        $recordSets = Get-AzDnsRecordSet -ZoneName $ZoneName -ResourceGroupName $ResourceGroup
    }
    else {
        $recordSets = Get-AzDnsRecordSet -ZoneName $ZoneName -ResourceGroupName $ResourceGroup -RecordType $RecordType
    }
    
    # Format the results
    $results = @()
    
    foreach ($recordSet in $recordSets) {
        $recordName = if ($recordSet.Name -eq "@") { $ZoneName } else { "$($recordSet.Name).$ZoneName" }
        
        switch ($recordSet.RecordType) {
            "A" {
                foreach ($record in $recordSet.Records) {
                    $results += [PSCustomObject]@{
                        Name = $recordSet.Name
                        Type = "A"
                        Value = $record.Ipv4Address
                        TTL = $recordSet.Ttl
                        FQDN = $recordName
                    }
                }
            }
            "CNAME" {
                foreach ($record in $recordSet.Records) {
                    $results += [PSCustomObject]@{
                        Name = $recordSet.Name
                        Type = "CNAME"
                        Value = $record.Cname
                        TTL = $recordSet.Ttl
                        FQDN = $recordName
                    }
                }
            }
            "MX" {
                foreach ($record in $recordSet.Records) {
                    $results += [PSCustomObject]@{
                        Name = $recordSet.Name
                        Type = "MX"
                        Value = "$($record.Preference) $($record.Exchange)"
                        TTL = $recordSet.Ttl
                        FQDN = $recordName
                        Preference = $record.Preference
                        Exchange = $record.Exchange
                    }
                }
            }
            "TXT" {
                foreach ($record in $recordSet.Records) {
                    $results += [PSCustomObject]@{
                        Name = $recordSet.Name
                        Type = "TXT"
                        Value = $record.Value -join " "
                        TTL = $recordSet.Ttl
                        FQDN = $recordName
                    }
                }
            }
            default {
                foreach ($record in $recordSet.Records) {
                    $results += [PSCustomObject]@{
                        Name = $recordSet.Name
                        Type = $recordSet.RecordType
                        Value = "See Azure Portal for details"
                        TTL = $recordSet.Ttl
                        FQDN = $recordName
                    }
                }
            }
        }
    }
    
    return $results
}