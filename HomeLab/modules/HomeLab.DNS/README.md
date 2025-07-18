# HomeLab.DNS Module

This module provides functionality for managing DNS zones and records in Azure as part of the HomeLab environment.

## Features

- Create and manage DNS zones in Azure
- Add and configure DNS records (A, CNAME, MX, TXT)
- List DNS zones and records
- Configure domain delegation

## Functions

### Public Functions

- `New-DNSZone`: Creates a new DNS zone in Azure
- `Add-DNSRecord`: Adds a DNS record to an Azure DNS zone

## Usage

```powershell
# Import the module
Import-Module HomeLab.DNS

# Create a DNS zone
New-DNSZone -DomainName "example.com" -ResourceGroup "myResourceGroup" -SubscriptionId "00000000-0000-0000-0000-000000000000"

# Add an A record
Add-DNSRecord -ZoneName "example.com" -RecordName "www" -RecordType "A" -Value "192.168.1.1" -ResourceGroup "myResourceGroup" -SubscriptionId "00000000-0000-0000-0000-000000000000"

# Add a CNAME record
Add-DNSRecord -ZoneName "example.com" -RecordName "blog" -RecordType "CNAME" -Value "myapp.azurewebsites.net" -ResourceGroup "myResourceGroup" -SubscriptionId "00000000-0000-0000-0000-000000000000"

# Add an MX record
Add-DNSRecord -ZoneName "example.com" -RecordName "@" -RecordType "MX" -Value "10 mail.example.com" -ResourceGroup "myResourceGroup" -SubscriptionId "00000000-0000-0000-0000-000000000000"

# Add a TXT record
Add-DNSRecord -ZoneName "example.com" -RecordName "@" -RecordType "TXT" -Value "v=spf1 include:spf.protection.outlook.com -all" -ResourceGroup "myResourceGroup" -SubscriptionId "00000000-0000-0000-0000-000000000000"
```

## Dependencies

- HomeLab.Core
- HomeLab.Azure
- Az PowerShell Module

## Notes

- After creating a DNS zone, you need to configure your domain registrar to use Azure's name servers
- DNS changes may take time to propagate (typically up to 24-48 hours)
- TTL (Time To Live) values control how long DNS records are cached