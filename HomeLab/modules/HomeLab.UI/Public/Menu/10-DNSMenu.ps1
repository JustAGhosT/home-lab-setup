function Show-DNSMenu {
    <#
    .SYNOPSIS
        Displays the DNS management menu.
    
    .DESCRIPTION
        This function displays the menu for DNS management options.
    
    .EXAMPLE
        Show-DNSMenu
    #>
    [CmdletBinding()]
    param()
    
    $menuItems = @(
        @{
            Name = "Create DNS Zone"
            Command = "Create-DNSZone"
        },
        @{
            Name = "Add DNS Record"
            Command = "Add-DNSRecordMenu"
        },
        @{
            Name = "List DNS Zones"
            Command = "List-DNSZones"
        },
        @{
            Name = "List DNS Records"
            Command = "List-DNSRecords"
        },
        @{
            Name = "Back to Main Menu"
            Command = "Back"
        }
    )
    
    Show-Menu -Title "DNS Management Menu" -MenuItems $menuItems
}