function Invoke-DNSHandler {
    <#
    .SYNOPSIS
        Handles DNS management menu commands.
    
    .DESCRIPTION
        This function processes commands from the DNS management menu.
    
    .PARAMETER Command
        The command to process.
    
    .EXAMPLE
        Invoke-DNSHandler -Command "Create-DNSZone"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    # Import required modules
    Import-Module HomeLab.Core
    Import-Module HomeLab.DNS
    
    # Get configuration
    $config = Get-Configuration
    
    switch ($Command) {
        "Create-DNSZone" {
            Clear-Host
            Write-Host "=== Create DNS Zone ===" -ForegroundColor Cyan
            
            # Get parameters
            $domainName = Read-Host "Enter domain name (e.g., example.com)"
            $resourceGroup = Read-Host "Enter resource group name"
            
            # Create DNS zone
            New-DNSZone -DomainName $domainName -ResourceGroup $resourceGroup -SubscriptionId $config.SubscriptionId
            
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Add-DNSRecordMenu" {
            Clear-Host
            Write-Host "=== Add DNS Record ===" -ForegroundColor Cyan
            
            # Get parameters
            $zoneName = Read-Host "Enter DNS zone name (e.g., example.com)"
            $resourceGroup = Read-Host "Enter resource group name"
            $recordName = Read-Host "Enter record name (e.g., www, or @ for root)"
            
            # Show record type menu
            Write-Host "`nSelect record type:"
            Write-Host "1. A (Address) Record"
            Write-Host "2. CNAME (Canonical Name) Record"
            Write-Host "3. MX (Mail Exchange) Record"
            Write-Host "4. TXT (Text) Record"
            
            $recordTypeChoice = Read-Host "Enter choice (1-4)"
            
            switch ($recordTypeChoice) {
                "1" { $recordType = "A" }
                "2" { $recordType = "CNAME" }
                "3" { $recordType = "MX" }
                "4" { $recordType = "TXT" }
                default {
                    Write-Host "Invalid choice. Returning to DNS menu."
                    Start-Sleep -Seconds 2
                    Show-DNSMenu
                    return
                }
            }
            
            # Get record value based on type
            switch ($recordType) {
                "A" {
                    $value = Read-Host "Enter IP address"
                }
                "CNAME" {
                    $value = Read-Host "Enter hostname (e.g., example.azurewebsites.net)"
                }
                "MX" {
                    $priority = Read-Host "Enter priority (e.g., 10)"
                    $exchange = Read-Host "Enter mail server hostname (e.g., mail.example.com)"
                    $value = "$priority $exchange"
                }
                "TXT" {
                    $value = Read-Host "Enter text value"
                }
            }
            
            # Get TTL
            $ttlInput = Read-Host "Enter TTL in seconds (default: 3600)"
            $ttl = if ([string]::IsNullOrWhiteSpace($ttlInput)) { 3600 } else { [int]$ttlInput }
            
            # Add DNS record
            Add-DNSRecord -ZoneName $zoneName -RecordName $recordName -RecordType $recordType -Value $value -TTL $ttl -ResourceGroup $resourceGroup -SubscriptionId $config.SubscriptionId
            
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "List-DNSZones" {
            Clear-Host
            Write-Host "=== DNS Zones ===" -ForegroundColor Cyan
            
            # Get resource group
            $resourceGroup = Read-Host "Enter resource group name (leave empty for all)"
            
            # List DNS zones
            if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
                Get-AzDnsZone | Format-Table Name, ResourceGroupName, ZoneType
            }
            else {
                Get-AzDnsZone -ResourceGroupName $resourceGroup | Format-Table Name, ResourceGroupName, ZoneType
            }
            
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "List-DNSRecords" {
            Clear-Host
            Write-Host "=== DNS Records ===" -ForegroundColor Cyan
            
            # Get parameters
            $zoneName = Read-Host "Enter DNS zone name (e.g., example.com)"
            $resourceGroup = Read-Host "Enter resource group name"
            
            # List DNS records
            Write-Host "`nA Records:" -ForegroundColor Yellow
            Get-AzDnsRecordSet -ZoneName $zoneName -ResourceGroupName $resourceGroup -RecordType A | Format-Table Name, Records
            
            Write-Host "`nCNAME Records:" -ForegroundColor Yellow
            Get-AzDnsRecordSet -ZoneName $zoneName -ResourceGroupName $resourceGroup -RecordType CNAME | Format-Table Name, Records
            
            Write-Host "`nMX Records:" -ForegroundColor Yellow
            Get-AzDnsRecordSet -ZoneName $zoneName -ResourceGroupName $resourceGroup -RecordType MX | Format-Table Name, Records
            
            Write-Host "`nTXT Records:" -ForegroundColor Yellow
            Get-AzDnsRecordSet -ZoneName $zoneName -ResourceGroupName $resourceGroup -RecordType TXT | Format-Table Name, Records
            
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        "Back" {
            # Return to main menu
            return
        }
        
        default {
            Write-Host "Unknown command: $Command"
            Start-Sleep -Seconds 2
        }
    }
    
    # Show the menu again
    Show-DNSMenu
}