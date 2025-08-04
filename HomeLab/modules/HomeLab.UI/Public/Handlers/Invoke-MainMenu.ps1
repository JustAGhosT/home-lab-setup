<#
.SYNOPSIS
    Handles the main menu interactions
.DESCRIPTION
    Processes user selections from the main menu and launches appropriate sub-menus or actions
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu.
.PARAMETER State
    Optional state hashtable for backward compatibility with existing code.
.PARAMETER Debug
    If specified, enables additional debug output.
.EXAMPLE
    Invoke-MainMenu
.EXAMPLE
    Invoke-MainMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Invoke-MainMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$State,
        
        [Parameter(Mandatory = $false)]
        [switch]$DebugMode
    )
    
    # Initialize exit flag
    $exitApplication = $false
    
    # Validate State parameter
    if ($null -eq $State) {
        $State = @{}
        if ($Debug) {
            Write-Host "DEBUG: Created empty State hashtable" -ForegroundColor Magenta
        }
    }
    
    # Check if Show-MainMenu exists before entering the loop
    if (-not (Get-Command -Name Show-MainMenu -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: Show-MainMenu function not found. Cannot display main menu." -ForegroundColor Red
        Write-Log -Message "Show-MainMenu function not found. Cannot display main menu." -Level "Error" -Force
        return $false
    }
    
    # Main menu loop
    do {
        try {
            if ($Debug) {
                Write-Host "DEBUG: About to call Show-MainMenu" -ForegroundColor Magenta
            }
            
            # Show main menu and get result
            $result = Show-MainMenu -ShowProgress:$ShowProgress -State $State
            
            if ($Debug) {
                Write-Host "DEBUG: Show-MainMenu returned: $($result | ConvertTo-Json -Depth 1 -Compress)" -ForegroundColor Magenta
            }
            
            # Validate result
            if ($null -eq $result) {
                Write-Host "WARNING: Show-MainMenu returned null result. Showing menu again..." -ForegroundColor Yellow
                Write-Log -Message "Show-MainMenu returned null result" -Level "Warning" -Force
                Start-Sleep -Seconds 2
                continue
            }
            
            # Process the user's choice
            if ($result.IsExit -eq $true) {
                # Exit the application
                $exitApplication = $true
                if ($Debug) {
                    Write-Host "DEBUG: User requested exit" -ForegroundColor Magenta
                }
                continue
            }
            
            if ($result.IsHelp -eq $true) {
                # Show help if requested
                if (Get-Command -Name Show-Help -ErrorAction SilentlyContinue) {
                    Show-Help -State $State
                }
                else {
                    Write-Host "`nHelp functionality is not implemented yet.`n" -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
                
                # Continue to next iteration (will show main menu again)
                continue
            }
            
            # Check if Choice property exists
            if (-not (Get-Member -InputObject $result -Name "Choice" -MemberType Properties)) {
                Write-Host "WARNING: Invalid menu result (missing Choice property). Showing menu again..." -ForegroundColor Yellow
                Write-Log -Message "Invalid menu result (missing Choice property)" -Level "Warning" -Force
                Start-Sleep -Seconds 2
                continue
            }
            
            # Handle menu selection with error handling
            try {
                switch ($result.Choice) {
                    "1" { 
                        if (Get-Command -Name Invoke-DeployMenu -ErrorAction SilentlyContinue) {
                            Invoke-DeployMenu -ShowProgress:$ShowProgress -State $State
                        } 
                        elseif (Get-Command -Name Show-DeployMenu -ErrorAction SilentlyContinue) {
                            # For backward compatibility
                            Show-DeployMenu -ShowProgress:$ShowProgress -State $State
                        }
                        else {
                            Write-Host "`nDeployment menu not implemented yet.`n" -ForegroundColor Yellow
                            Start-Sleep -Seconds 2
                        }
                    }
                    "2" { 
                        if (Get-Command -Name Invoke-VpnCertMenu -ErrorAction SilentlyContinue) {
                            Invoke-VpnCertMenu -ShowProgress:$ShowProgress -State $State
                        }
                        elseif (Get-Command -Name Show-VpnCertMenu -ErrorAction SilentlyContinue) {
                            # For backward compatibility
                            Show-VpnCertMenu -ShowProgress:$ShowProgress -State $State
                        }
                        else {
                            Write-Host "`nVPN Certificate menu not implemented yet.`n" -ForegroundColor Yellow
                            Start-Sleep -Seconds 2
                        }
                    }
                    "3" { 
                        if (Get-Command -Name Invoke-VpnGatewayMenu -ErrorAction SilentlyContinue) {
                            Invoke-VpnGatewayMenu -ShowProgress:$ShowProgress -State $State
                        }
                        elseif (Get-Command -Name Show-VpnGatewayMenu -ErrorAction SilentlyContinue) {
                            # For backward compatibility
                            Show-VpnGatewayMenu -ShowProgress:$ShowProgress -State $State
                        }
                        else {
                            Write-Host "`nVPN Gateway menu not implemented yet.`n" -ForegroundColor Yellow
                            Start-Sleep -Seconds 2
                        }
                    }
                    "4" { 
                        if (Get-Command -Name Invoke-VpnClientMenu -ErrorAction SilentlyContinue) {
                            Invoke-VpnClientMenu -ShowProgress:$ShowProgress -State $State
                        }
                        elseif (Get-Command -Name Show-VpnClientMenu -ErrorAction SilentlyContinue) {
                            # For backward compatibility
                            Show-VpnClientMenu -ShowProgress:$ShowProgress -State $State
                        }
                        else {
                            Write-Host "`nVPN Client menu not implemented yet.`n" -ForegroundColor Yellow
                            Start-Sleep -Seconds 2
                        }
                    }
                    "5" { 
                        if (Get-Command -Name Invoke-NatGatewayMenu -ErrorAction SilentlyContinue) {
                            Invoke-NatGatewayMenu -ShowProgress:$ShowProgress -State $State
                        }
                        elseif (Get-Command -Name Show-NatGatewayMenu -ErrorAction SilentlyContinue) {
                            # For backward compatibility
                            Show-NatGatewayMenu -ShowProgress:$ShowProgress -State $State
                        }
                        else {
                            Write-Host "`nNAT Gateway menu not implemented yet.`n" -ForegroundColor Yellow
                            Start-Sleep -Seconds 2
                        }
                    }
                    "6" { 
                        if (Get-Command -Name Invoke-DocumentationMenu -ErrorAction SilentlyContinue) {
                            Invoke-DocumentationMenu -ShowProgress:$ShowProgress -State $State
                        }
                        elseif (Get-Command -Name Show-DocumentationMenu -ErrorAction SilentlyContinue) {
                            # For backward compatibility
                            Show-DocumentationMenu -ShowProgress:$ShowProgress -State $State
                        }
                        else {
                            Write-Host "`nDocumentation menu not implemented yet.`n" -ForegroundColor Yellow
                            Start-Sleep -Seconds 2
                        }
                    }
                    "7" { 
                        if (Get-Command -Name Invoke-SettingsMenu -ErrorAction SilentlyContinue) {
                            Invoke-SettingsMenu -ShowProgress:$ShowProgress -State $State
                        }
                        elseif (Get-Command -Name Show-SettingsMenu -ErrorAction SilentlyContinue) {
                            # For backward compatibility
                            Show-SettingsMenu -ShowProgress:$ShowProgress -State $State
                        }
                        else {
                            Write-Host "`nSettings menu not implemented yet.`n" -ForegroundColor Yellow
                            Start-Sleep -Seconds 2
                        }
                    }
                    "8" { 
                        if (Get-Command -Name Invoke-KvmSetupMenu -ErrorAction SilentlyContinue) {
                            Invoke-KvmSetupMenu -ShowProgress:$ShowProgress -State $State
                        }
                        elseif (Get-Command -Name Show-KvmSetupMenu -ErrorAction SilentlyContinue) {
                            # For backward compatibility
                            Show-KvmSetupMenu -ShowProgress:$ShowProgress -State $State
                        }
                        else {
                            Write-Host "`nSoftware KVM Setup menu not implemented yet.`n" -ForegroundColor Yellow
                            Start-Sleep -Seconds 2
                        }
                    }"9" {
                        # DIRECT REPLACEMENT - Bypass all complex logic
                        Clear-Host
                        
                        # First load our emergency direct replacement
                        $fixPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Website-QuickFix.ps1"
                        if (Test-Path $fixPath) {
                            try {
                                # Load the direct menu script
                                . $fixPath
                               
                               # Call the direct menu function
                               Show-WebsiteMenuDirect
                            }
                            catch {
                                # If that fails, use ultra simple built-in menu
                                Clear-Host
                                Write-Host "=== WEBSITE DEPLOYMENT MENU ===" -ForegroundColor Cyan
                                Write-Host ""
                                Write-Host "1. Deploy Static Website" -ForegroundColor White
                                Write-Host "2. Deploy App Service Website" -ForegroundColor White
                                Write-Host "3. Return to Main Menu" -ForegroundColor Yellow
                                Write-Host ""
                                
                                $choice = Read-Host "Select an option (1-3)"
                                
                                switch ($choice) {
                                    "1" {
                                        Clear-Host
                                        Write-Host "Static Website Deployment" -ForegroundColor Cyan
                                        $rg = Read-Host "Resource Group Name"
                                        $app = Read-Host "App Name"
                                        $sub = Read-Host "Subscription ID"
                                        
                                        if ($rg -and $app -and $sub) {
                                            try {
                                                Deploy-Website -DeploymentType static -ResourceGroup $rg -AppName $app -SubscriptionId $sub
                                            }
                                            catch {
                                                Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
                                            }
                                        }
                                        else {
                                            Write-Host "Missing required parameters." -ForegroundColor Red
                                        }
                                        
                                        Read-Host "Press Enter to continue"
                                    }
                                    "2" {
                                        Clear-Host
                                        Write-Host "App Service Deployment" -ForegroundColor Cyan
                                        $rg = Read-Host "Resource Group Name"
                                        $app = Read-Host "App Name"
                                        $sub = Read-Host "Subscription ID"
                                        
                                        if ($rg -and $app -and $sub) {
                                            try {
                                                Deploy-Website -DeploymentType appservice -ResourceGroup $rg -AppName $app -SubscriptionId $sub
                                            }
                                            catch {
                                                Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
                                            }
                                        }
                                        else {
                                            Write-Host "Missing required parameters." -ForegroundColor Red
                                        }
                                        
                                        Read-Host "Press Enter to continue"
                                    }
                                }
                            }
                        }
                        else {
                            # If no fix file is found, use inline simple menu
                            Clear-Host
                            Write-Host "=== WEBSITE DEPLOYMENT MENU ===" -ForegroundColor Cyan
                            Write-Host ""
                            Write-Host "1. Deploy Static Website" -ForegroundColor White
                            Write-Host "2. Deploy App Service Website" -ForegroundColor White
                            Write-Host "3. Return to Main Menu" -ForegroundColor Yellow
                            Write-Host ""
                            
                            $choice = Read-Host "Select an option (1-3)"
                            
                            switch ($choice) {
                                "1" {
                                    Clear-Host
                                    Write-Host "Static Website Deployment" -ForegroundColor Cyan
                                    $rg = Read-Host "Resource Group Name"
                                    $app = Read-Host "App Name"
                                    $sub = Read-Host "Subscription ID"
                                    
                                    if ($rg -and $app -and $sub) {
                                        try {
                                            Deploy-Website -DeploymentType static -ResourceGroup $rg -AppName $app -SubscriptionId $sub
                                        }
                                        catch {
                                            Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
                                        }
                                    }
                                    else {
                                        Write-Host "Missing required parameters." -ForegroundColor Red
                                    }
                                    
                                    Read-Host "Press Enter to continue"
                                }
                                "2" {
                                    Clear-Host
                                    Write-Host "App Service Deployment" -ForegroundColor Cyan
                                    $rg = Read-Host "Resource Group Name"
                                    $app = Read-Host "App Name"
                                    $sub = Read-Host "Subscription ID"
                                    
                                    if ($rg -and $app -and $sub) {
                                        try {
                                            Deploy-Website -DeploymentType appservice -ResourceGroup $rg -AppName $app -SubscriptionId $sub
                                        }
                                        catch {
                                            Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
                                        }
                                    }
                                    else {
                                        Write-Host "Missing required parameters." -ForegroundColor Red
                                    }
                                    
                                    Read-Host "Press Enter to continue"
                                }
                            }
                        }
                    }
                    "10" {
                        try {
                            # For DNS management menu - use our simple workaround if Show-DNSMenu fails
                            $dnsMenuItems = @{
                                "1" = "Create DNS Zone"
                                "2" = "Add DNS Record"
                                "3" = "List DNS Zones"
                                "4" = "List DNS Records"
                            }
                            
                            # First check if we have the flexible menu function
                            if (Get-Command -Name Show-FlexibleMenu -ErrorAction SilentlyContinue) {
                                do {
                                    $result = Show-FlexibleMenu -Title "DNS Management Menu" -MenuItems $dnsMenuItems `
                                                            -ExitOption "0" -ExitText "Return to Main Menu" `
                                                            -ValidateInput
                                    
                                    if ($result.IsExit -eq $true) {
                                        break
                                    }
                                    
                                    # Handle simple DNS operations directly
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
                            } else {
                                # Try the original method if flexible menu isn't available
                                if (Get-Command -Name Show-DNSMenu -ErrorAction SilentlyContinue) {
                                    Show-DNSMenu
                                } else {
                                    Write-Host "`nDNS Management menu not implemented yet.`n" -ForegroundColor Yellow
                                    Start-Sleep -Seconds 2
                                }
                            }
                        }
                        catch {
                            Write-Host "Error processing DNS menu: $($_.Exception.Message)" -ForegroundColor Red
                            Start-Sleep -Seconds 2
                        }
                    }
                    "0" {
                        # Exit option - this is handled by the IsExit property, but included for completeness
                        $exitApplication = $true
                    }
                    default {
                        Write-Host "`nInvalid menu choice: $($result.Choice)`n" -ForegroundColor Yellow
                        Start-Sleep -Seconds 2
                    }
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                Write-Host "`nError processing menu choice: $errorMessage`n" -ForegroundColor Red
                Write-Log -Message "Error processing menu choice: $errorMessage" -Level "Error" -Force
                Start-Sleep -Seconds 2
            }
            
            # Only show progress on first display
            $ShowProgress = $false
            
        }
        catch {
            $errorMessage = $_.Exception.Message
            $errorLine = $_.InvocationInfo.ScriptLineNumber
            $errorScript = $_.InvocationInfo.ScriptName
            
            Write-Host "`nError in main menu: $errorMessage`n" -ForegroundColor Red
            Write-Log -Message "Error in main menu: $errorMessage" -Level "Error" -Force
            Write-Log -Message "Script: $errorScript, Line: $errorLine" -Level "Error" -Force
            
            # Ask if user wants to try again
            Write-Host "Would you like to try again? (Y/N)" -ForegroundColor Yellow
            $retry = Read-Host
            if ($retry -ne "Y" -and $retry -ne "y") {
                $exitApplication = $true
            }
        }
        
    } while (-not $exitApplication)
    
    # Return success
    return $true
}
