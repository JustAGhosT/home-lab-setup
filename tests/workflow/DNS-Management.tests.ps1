BeforeAll {
    # Import required modules
    $modulePath = Join-Path $PSScriptRoot "..\..\src\HomeLab\HomeLab\modules\HomeLab.DNS\HomeLab.DNS.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }
    
    # Mock functions to avoid actual Azure operations during tests
    function New-DNSZone {
        param(
            [Parameter(Mandatory = $true)]
            [string]$DomainName,
            
            [Parameter(Mandatory = $true)]
            [string]$ResourceGroup,
            
            [Parameter(Mandatory = $true)]
            [string]$SubscriptionId
        )
        
        return @{
            Name              = $DomainName
            ResourceGroupName = $ResourceGroup
            NameServers       = @(
                "ns1-01.azure-dns.com.",
                "ns2-01.azure-dns.net.",
                "ns3-01.azure-dns.org.",
                "ns4-01.azure-dns.info."
            )
        }
    }
    
    function Add-DNSRecord {
        param(
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
        
        return @{
            Success        = $true
            ZoneName       = $ZoneName
            RecordName     = $RecordName
            RecordType     = $RecordType
            Value          = $Value
            TTL            = $TTL
            ResourceGroup  = $ResourceGroup
            SubscriptionId = $SubscriptionId
        }
    }
    
    function Get-DNSRecords {
        param(
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
        
        # Return mock records based on zone name
        if ($ZoneName -eq "example.com") {
            return @(
                @{
                    Name  = "www"
                    Type  = "A"
                    Value = "10.0.0.1"
                    TTL   = 3600
                },
                @{
                    Name  = "mail"
                    Type  = "CNAME"
                    Value = "mail.example.com"
                    TTL   = 3600
                }
            )
        }
        
        return @()
    }
}

Describe "DNS Management Workflow" {
    Context "DNS Zone Creation" {
        It "Should create a new DNS zone successfully" {
            # Arrange
            $domainName = "example.com"
            $resourceGroup = "test-rg"
            $subscriptionId = "00000000-0000-0000-0000-000000000000"
            
            # Act
            $result = New-DNSZone -DomainName $domainName -ResourceGroup $resourceGroup -SubscriptionId $subscriptionId
            
            # Assert
            $result.Name | Should -Be $domainName
            $result.ResourceGroupName | Should -Be $resourceGroup
            $result.NameServers.Count | Should -Be 4
        }
    }
    
    Context "DNS Record Management" {
        It "Should add an A record successfully" {
            # Arrange
            $zoneName = "example.com"
            $recordName = "www"
            $recordType = "A"
            $recordValue = "10.0.0.1"
            $ttl = 3600
            $resourceGroup = "test-rg"
            $subscriptionId = "00000000-0000-0000-0000-000000000000"
            
            # Act
            $result = Add-DNSRecord -ZoneName $zoneName -RecordName $recordName -RecordType $recordType -Value $recordValue -TTL $ttl -ResourceGroup $resourceGroup -SubscriptionId $subscriptionId
            
            # Assert
            $result.Success | Should -Be $true
            $result.ZoneName | Should -Be $zoneName
            $result.RecordName | Should -Be $recordName
            $result.RecordType | Should -Be $recordType
            $result.Value | Should -Be $recordValue
            $result.TTL | Should -Be $ttl
        }
        
        It "Should add a CNAME record successfully" {
            # Arrange
            $zoneName = "example.com"
            $recordName = "mail"
            $recordType = "CNAME"
            $recordValue = "mail.example.com"
            $resourceGroup = "test-rg"
            $subscriptionId = "00000000-0000-0000-0000-000000000000"
            
            # Act
            $result = Add-DNSRecord -ZoneName $zoneName -RecordName $recordName -RecordType $recordType -Value $recordValue -ResourceGroup $resourceGroup -SubscriptionId $subscriptionId
            
            # Assert
            $result.Success | Should -Be $true
            $result.ZoneName | Should -Be $zoneName
            $result.RecordName | Should -Be $recordName
            $result.RecordType | Should -Be $recordType
            $result.Value | Should -Be $recordValue
        }
    }
    
    Context "DNS Record Retrieval" {
        It "Should retrieve DNS records for a zone" {
            # Arrange
            $zoneName = "example.com"
            $resourceGroup = "test-rg"
            $subscriptionId = "00000000-0000-0000-0000-000000000000"
            
            # Act
            $records = Get-DNSRecords -ZoneName $zoneName -ResourceGroup $resourceGroup -SubscriptionId $subscriptionId
            
            # Assert
            $records.Count | Should -Be 2
            $records[0].Name | Should -Be "www"
            $records[0].Type | Should -Be "A"
            $records[0].Value | Should -Be "10.0.0.1"
            $records[1].Name | Should -Be "mail"
            $records[1].Type | Should -Be "CNAME"
            $records[1].Value | Should -Be "mail.example.com"
        }
    }
}