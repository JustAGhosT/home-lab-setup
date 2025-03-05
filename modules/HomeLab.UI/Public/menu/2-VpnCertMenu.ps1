function Show-VpnCertMenu {
    $menuItems = @{
        "1" = "Create New Root Certificate"
        "2" = "Create Client Certificate"
        "3" = "Add Client Certificate to Existing Root"
        "4" = "Upload Certificate to VPN Gateway"
        "5" = "List All Certificates"
    }
    return Show-Menu -Title "VPN CERTIFICATE MENU" -MenuItems $menuItems -ExitOption "0"
}

Export-ModuleMember -Function Show-VpnCertMenu
