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
    
    $menuItems = @(
        @{
            Name = "Browse and Select Project"
            Command = "Browse-Project"
        },
        @{
            Name = "Deploy Static Website"
            Command = "Deploy-StaticWebsite"
        },
        @{
            Name = "Deploy App Service Website"
            Command = "Deploy-AppServiceWebsite"
        },
        @{
            Name = "Auto-Detect and Deploy Website"
            Command = "Deploy-AutoDetectWebsite"
        },
        @{
            Name = "Configure Custom Domain"
            Command = "Configure-WebsiteCustomDomain"
        },
        @{
            Name = "Add GitHub Workflows"
            Command = "Add-GitHubWorkflowsMenu"
        },
        @{
            Name = "Show Deployment Type Info"
            Command = "Show-DeploymentTypeInfoMenu"
        },
        @{
            Name = "List Deployed Websites"
            Command = "List-DeployedWebsites"
        },
        @{
            Name = "Back to Main Menu"
            Command = "Back"
        }
    )
    
    Show-Menu -Title "Website Deployment Menu" -MenuItems $menuItems
}