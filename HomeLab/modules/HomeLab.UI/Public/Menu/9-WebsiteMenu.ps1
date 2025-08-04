function Show-WebsiteMenu {
    <#
    .SYNOPSIS
        Displays the website deployment menu.
    
    .DESCRIPTION
        This function displays the menu for website deployment options.
    
    .EXAMPLE
        Show-WebsiteMenu
    #>
    [CmdletBinding()]
    param()
    
    $menuItems = @{
        "1"  = "Browse and Select Project"
        "2"  = "Deploy Static Website (Azure)"
        "3"  = "Deploy App Service Website (Azure)"
        "4"  = "Deploy to Vercel (Next.js, React, Vue)"
        "5"  = "Deploy to Netlify (Static sites, JAMstack)"
        "6"  = "Deploy to AWS (S3 + CloudFront, Amplify)"
        "7"  = "Deploy to Google Cloud (Cloud Run, App Engine)"
        "8"  = "Auto-Detect and Deploy Website"
        "9"  = "Configure Custom Domain"
        "10" = "Add GitHub Workflows"
        "11" = "Show Deployment Type Info"
        "12" = "List Deployed Websites"
    }
    
    # Debug: Verify menuItems is a hashtable
    Write-Host "DEBUG: MenuItems type: $($menuItems.GetType().FullName)" -ForegroundColor Magenta
    Write-Host "DEBUG: MenuItems count: $($menuItems.Count)" -ForegroundColor Magenta
    
    do {
        try {
            $result = Show-Menu -Title "Website Deployment Menu" -MenuItems $menuItems `
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
            "1" { Invoke-WebsiteHandler -Command "Browse-Project" }
            "2" { Invoke-WebsiteHandler -Command "Deploy-StaticWebsite" }
            "3" { Invoke-WebsiteHandler -Command "Deploy-AppServiceWebsite" }
            "4" { Invoke-WebsiteHandler -Command "Deploy-VercelWebsite" }
            "5" { Invoke-WebsiteHandler -Command "Deploy-NetlifyWebsite" }
            "6" { Invoke-WebsiteHandler -Command "Deploy-AWSWebsite" }
            "7" { Invoke-WebsiteHandler -Command "Deploy-GCPWebsite" }
            "8" { Invoke-WebsiteHandler -Command "Deploy-AutoDetectWebsite" }
            "9" { Invoke-WebsiteHandler -Command "Configure-WebsiteCustomDomain" }
            "10" { Invoke-WebsiteHandler -Command "Add-GitHubWorkflowsMenu" }
            "11" { Invoke-WebsiteHandler -Command "Show-DeploymentTypeInfoMenu" }
            "12" { Invoke-WebsiteHandler -Command "List-DeployedWebsites" }
            default {
                Write-Host "Invalid selection: $($result.Choice)" -ForegroundColor Red
                Start-Sleep 2
            }
        }
    } while ($true)
}