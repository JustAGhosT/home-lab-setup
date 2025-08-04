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
    
    $menuItems = @{
        "1" = "Create DNS Zone"
        "2" = "Add DNS Record"
        "3" = "List DNS Zones"
        "4" = "List DNS Records"
    }
    
    # Debug: Verify menuItems is a hashtable
    Write-Host "DEBUG: MenuItems type: $($menuItems.GetType().FullName)" -ForegroundColor Magenta
    Write-Host "DEBUG: MenuItems count: $($menuItems.Count)" -ForegroundColor Magenta
    
    do {
        try {
            $result = Show-Menu -Title "DNS Management Menu" -MenuItems $menuItems `
                                -ExitOption "0" -ExitText "Return to Main Menu" `
                                -ValidateInput
        }
        catch {
            Write-Host "ERROR in Show-Menu call: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "ERROR: MenuItems type at error: $($menuItems.GetType().FullName)" -ForegroundColor Red
            throw
        }
        
        if ($result.IsExit -eq $true) {
            break
        }
        
        # Handle the menu selection
        switch ($result.Choice) {
            "1" { 
                # Create DNS Zone
                Write-Host "DNS Zone creation functionality coming soon..." -ForegroundColor Yellow
                Read-Host "Press Enter to continue"
            }
            "2" { 
                # Add DNS Record
                Write-Host "DNS Record addition functionality coming soon..." -ForegroundColor Yellow
                Read-Host "Press Enter to continue"
            }
            "3" { 
                # List DNS Zones
                Write-Host "DNS Zone listing functionality coming soon..." -ForegroundColor Yellow
                Read-Host "Press Enter to continue"
            }
            "4" { 
                # List DNS Records
                Write-Host "DNS Record listing functionality coming soon..." -ForegroundColor Yellow
                Read-Host "Press Enter to continue"
            }
            default {
                Write-Host "Invalid selection: $($result.Choice)" -ForegroundColor Red
                Start-Sleep 2
            }
        }
    } while ($true)
}