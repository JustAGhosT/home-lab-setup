function Show-DeployMenu {
    $menuItems = @{
        "1" = "Full Deployment (All Resources)"
        "2" = "Deploy Network Only"
        "3" = "Deploy VPN Gateway Only"
        "4" = "Deploy NAT Gateway Only"
        "5" = "Check Deployment Status"
    }
    # Call the generic menu function with a title and the menu items.
    return Show-Menu -Title "DEPLOYMENT MENU" -MenuItems $menuItems -ExitOption "0"
}

Export-ModuleMember -Function Show-DeployMenu
