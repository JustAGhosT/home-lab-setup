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
                    }
                    "9" {
                        if ((Get-Command -Name Invoke-WebsiteHandler -ErrorAction SilentlyContinue) -and
                            (Get-Command -Name Show-WebsiteMenu -ErrorAction SilentlyContinue)) {
                            Show-WebsiteMenu
                        }
                        else {
                            Write-Host "`nWebsite Deployment menu not implemented yet.`n" -ForegroundColor Yellow
                            Start-Sleep -Seconds 2
                        }
                    }
                    "10" {
                        if ((Get-Command -Name Invoke-DNSHandler -ErrorAction SilentlyContinue) -and
                            (Get-Command -Name Show-DNSMenu -ErrorAction SilentlyContinue)) {
                            Show-DNSMenu
                        }
                        else {
                            Write-Host "`nDNS Management menu not implemented yet.`n" -ForegroundColor Yellow
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
